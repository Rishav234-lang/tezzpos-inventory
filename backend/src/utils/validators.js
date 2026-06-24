const { z } = require('zod');

// Auth validators
const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(6),
  newPassword: z.string().min(6),
});

// Vendor validators
const vendorSchema = z.object({
  name: z.string().min(1).max(200),
  mobile: z.string().max(15).optional().nullable(),
  gstNumber: z.string().max(20).optional().nullable(),
  email: z.string().email().optional().nullable(),
  address: z.string().max(500).optional().nullable(),
});

// Product validators
const productSchema = z.object({
  name: z.string().min(1).max(200),
  sku: z.string().max(50).optional().nullable(),
  barcode: z.string().max(50).optional().nullable(),
  categoryId: z.string().optional().nullable(),
  unit: z.string().default('PCS'),
  sellingPrice: z.number().positive(),
  minStockLevel: z.number().int().min(0).default(10),
  status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
});

// Purchase validators
const purchaseItemSchema = z.object({
  productId: z.string(),
  quantity: z.number().int().positive(),
  purchasePrice: z.number().positive(),
  mrp: z.number().positive(),
  expiryDate: z.string().datetime().optional().nullable(),
});

const purchaseSchema = z.object({
  vendorId: z.string(),
  invoiceNumber: z.string().min(1),
  purchaseDate: z.string().datetime(),
  paidAmount: z.number().min(0).default(0),
  notes: z.string().optional().nullable(),
  items: z.array(purchaseItemSchema).min(1),
});

// Customer validators
const customerSchema = z.object({
  name: z.string().min(1).max(200),
  mobile: z.string().max(15).optional().nullable(),
  gstNumber: z.string().max(20).optional().nullable(),
  email: z.string().email().optional().nullable(),
  address: z.string().max(500).optional().nullable(),
});

// Sale validators
const saleItemSchema = z.object({
  productId: z.string(),
  quantity: z.number().int().positive(),
  sellingPrice: z.number().positive(),
  discount: z.number().min(0).default(0),
  taxAmount: z.number().min(0).default(0),
});

const saleSchema = z.object({
  customerId: z.string().optional().nullable(),
  invoiceDate: z.string().datetime(),
  discount: z.number().min(0).default(0),
  taxAmount: z.number().min(0).default(0),
  paidAmount: z.number().min(0).default(0),
  paymentMethod: z.enum(['CASH', 'UPI', 'CARD', 'BANK_TRANSFER']).optional().nullable(),
  notes: z.string().optional().nullable(),
  items: z.array(saleItemSchema).min(1),
});

// Sale Return validators
const saleReturnItemSchema = z.object({
  productId: z.string(),
  quantity: z.number().int().positive(),
  price: z.number().positive(),
});

const saleReturnSchema = z.object({
  saleId: z.string(),
  returnDate: z.string().datetime(),
  reason: z.string().optional().nullable(),
  refundAmount: z.number().min(0).default(0),
  items: z.array(saleReturnItemSchema).min(1),
});

// Payment validators
const customerPaymentSchema = z.object({
  customerId: z.string(),
  amount: z.number().positive(),
  paymentDate: z.string().datetime(),
  paymentMethod: z.enum(['CASH', 'UPI', 'CARD', 'BANK_TRANSFER']),
  notes: z.string().optional().nullable(),
});

const vendorPaymentSchema = z.object({
  vendorId: z.string(),
  amount: z.number().positive(),
  paymentDate: z.string().datetime(),
  paymentMethod: z.enum(['CASH', 'UPI', 'CARD', 'BANK_TRANSFER']),
  notes: z.string().optional().nullable(),
});

// Plan validators
const planSchema = z.object({
  name: z.string().min(1).max(100),
  monthlyPrice: z.number().positive(),
  yearlyPrice: z.number().positive(),
  description: z.string().optional().nullable(),
  status: z.enum(['ACTIVE', 'INACTIVE']).default('ACTIVE'),
});

// Company validators
const companySchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
  phone: z.string().max(15).optional().nullable(),
  address: z.string().max(500).optional().nullable(),
  gstNumber: z.string().max(20).optional().nullable(),
  ownerName: z.string().min(1).max(200),
  ownerEmail: z.string().email(),
  ownerPassword: z.string().min(6),
});

// Category validators
const categorySchema = z.object({
  name: z.string().min(1).max(100),
});

module.exports = {
  loginSchema,
  changePasswordSchema,
  vendorSchema,
  productSchema,
  purchaseSchema,
  customerSchema,
  saleSchema,
  saleReturnSchema,
  customerPaymentSchema,
  vendorPaymentSchema,
  planSchema,
  companySchema,
  categorySchema,
};
