const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Create Super Admin
  const hashedPassword = await bcrypt.hash(process.env.SUPER_ADMIN_PASSWORD || 'Admin@123', 10);
  
  const superAdmin = await prisma.superAdmin.upsert({
    where: { email: process.env.SUPER_ADMIN_EMAIL || 'admin@tezzpos.com' },
    update: {},
    create: {
      email: process.env.SUPER_ADMIN_EMAIL || 'admin@tezzpos.com',
      password: hashedPassword,
      name: 'Super Admin',
    },
  });
  console.log('Super Admin created:', superAdmin.email);

  // Create Plans
  const plans = [
    { id: 'free-trial-3-days', name: 'Free Trial - 3 Days', monthlyPrice: 0, yearlyPrice: 0, description: 'Try TezzPOS free for 3 days.', status: 'ACTIVE' },
    { name: 'Starter', monthlyPrice: 199, yearlyPrice: 1999, description: 'For small businesses', status: 'ACTIVE' },
    { name: 'Business', monthlyPrice: 499, yearlyPrice: 4999, description: 'For growing businesses', status: 'ACTIVE' },
    { name: 'Enterprise', monthlyPrice: 999, yearlyPrice: 9999, description: 'For large businesses', status: 'ACTIVE' },
  ];

  for (const plan of plans) {
    const { id, ...planData } = plan;
    const planId = id || plan.name.toLowerCase();
    await prisma.plan.upsert({
      where: { id: planId },
      update: planData,
      create: { id: planId, ...planData },
    });
  }
  console.log('Plans created');

  // Create Demo Company
  const ownerPassword = await bcrypt.hash('Owner@123', 10);
  
  const company = await prisma.company.upsert({
    where: { email: 'demo@store.com' },
    update: {},
    create: {
      name: 'Demo Store',
      email: 'demo@store.com',
      phone: '9876543210',
      address: '123 Main St, City',
      status: 'ACTIVE',
      owner: {
        create: {
          name: 'Demo Owner',
          email: 'owner@demo.com',
          password: ownerPassword,
          phone: '9876543210',
        },
      },
    },
  });
  console.log('Demo Company created:', company.name);

  // Create subscription for demo company
  const startDate = new Date();
  const endDate = new Date();
  endDate.setMonth(endDate.getMonth() + 1);

  await prisma.companySubscription.upsert({
    where: { companyId: company.id },
    update: {},
    create: {
      companyId: company.id,
      planId: 'business',
      billingCycle: 'MONTHLY',
      startDate,
      endDate,
      status: 'ACTIVE',
    },
  });
  console.log('Demo subscription created');

  console.log('Seeding completed!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
