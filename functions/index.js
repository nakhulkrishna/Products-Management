const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");

initializeApp();

function asNumber(value) {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    const parsed = Number(value.trim());
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function normalizeProductDocId(code) {
  return String(code || "").replaceAll("#", "").trim().toLowerCase();
}

exports.deductInventoryOnOrderCreate = onDocumentCreated(
    "catalog_orders/{orderId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;

      const order = snapshot.data() || {};
      const sync = order.inventorySync || {};
      if (sync.stockDeducted === true) {
        return;
      }

      const items = Array.isArray(order.items) ? order.items : [];
      const consumeByProduct = new Map();

      for (const rawItem of items) {
        const item = rawItem || {};
        const productDocId = normalizeProductDocId(item.productCode);
        if (!productDocId) continue;

        const qtyBaseDirect = asNumber(item.qtyBase);
        const qty = asNumber(item.qty);
        const conversion = asNumber(item.conversionToBaseUnit);
        const qtyBase = qtyBaseDirect > 0 ? qtyBaseDirect : qty * conversion;

        if (qtyBase <= 0) continue;
        consumeByProduct.set(
            productDocId,
            (consumeByProduct.get(productDocId) || 0) + qtyBase,
        );
      }

      const db = getFirestore();
      const orderRef = snapshot.ref;

      if (consumeByProduct.size === 0) {
        await orderRef.set({
          inventorySync: {
            stockDeducted: true,
            deductedBy: "cloud_function",
            deductedAt: FieldValue.serverTimestamp(),
            note: "No valid order items found for stock deduction.",
          },
        }, {merge: true});
        return;
      }

      await db.runTransaction(async (tx) => {
        const warnings = [];

        for (const [productDocId, consumedBase] of consumeByProduct.entries()) {
          const productRef = db.collection("catalog_products").doc(productDocId);
          const productSnap = await tx.get(productRef);
          if (!productSnap.exists) {
            warnings.push(`Missing product: ${productDocId}`);
            continue;
          }

          const productData = productSnap.data() || {};
          const inventory = productData.inventory || {};
          const currentAvailable =
            asNumber(inventory.availableQtyBaseUnit) ||
            asNumber(inventory.baseUnitQty);

          const nextAvailable = Math.max(0, currentAvailable - consumedBase);
          if (currentAvailable < consumedBase) {
            warnings.push(
                `Stock below requested for ${productDocId}: requested ${consumedBase}, available ${currentAvailable}`,
            );
          }

          tx.set(productRef, {
            inventory: {
              availableQtyBaseUnit: nextAvailable,
            },
            audit: {
              updatedAt: FieldValue.serverTimestamp(),
            },
          }, {merge: true});
        }

        tx.set(orderRef, {
          inventorySync: {
            stockDeducted: true,
            deductedBy: "cloud_function",
            deductedAt: FieldValue.serverTimestamp(),
            warningCount: warnings.length,
            warnings: warnings.slice(0, 20),
          },
        }, {merge: true});
      });
    },
);
