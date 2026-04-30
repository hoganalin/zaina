import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const channels = [
  { slug: 'rent', name: '租屋', icon: '🏠', sortOrder: 1 },
  { slug: 'secondhand', name: '二手拍', icon: '🏷️', sortOrder: 2 },
  { slug: 'ticket', name: '票券', icon: '🎟️', sortOrder: 3 },
  { slug: 'travel', name: '旅遊', icon: '✈️', sortOrder: 4 },
  { slug: 'travel-buddy', name: '旅伴', icon: '🧳', sortOrder: 5 },
  { slug: 'food', name: '美食', icon: '🍜', sortOrder: 6 },
  { slug: 'asia', name: '亞洲', icon: '🌏', sortOrder: 7 },
  { slug: 'spain', name: '西班牙', icon: '🇪🇸', sortOrder: 8 },
  { slug: 'europe', name: '歐洲', icon: '🇪🇺', sortOrder: 9 },
  { slug: 'solo-travel', name: '獨旅', icon: '🚶', sortOrder: 10 },
  { slug: 'study', name: '升學', icon: '🎓', sortOrder: 11 },
  { slug: 'mood', name: '心情', icon: '💭', sortOrder: 12 },
];

const interests = [
  // active
  { slug: 'running', name: '跑步', category: 'active' as const },
  { slug: 'fitness', name: '健身', category: 'active' as const },
  { slug: 'swimming', name: '游泳', category: 'active' as const },
  { slug: 'hiking', name: '爬山', category: 'active' as const },
  { slug: 'dancing', name: '跳舞', category: 'active' as const },
  { slug: 'cycling', name: '腳踏車', category: 'active' as const },
  // static
  { slug: 'animation', name: '動漫', category: 'static' as const },
  { slug: 'movies', name: '電影', category: 'static' as const },
  { slug: 'reading', name: '看書', category: 'static' as const },
  { slug: 'music', name: '音樂', category: 'static' as const },
  { slug: 'violin', name: '提琴', category: 'static' as const },
  { slug: 'meditation', name: '冥想', category: 'static' as const },
];

async function main() {
  for (const ch of channels) {
    await prisma.channel.upsert({
      where: { slug: ch.slug },
      create: ch,
      update: ch,
    });
  }
  for (const i of interests) {
    await prisma.interest.upsert({
      where: { slug: i.slug },
      create: i,
      update: i,
    });
  }
  console.log(`Seeded ${channels.length} channels and ${interests.length} interests.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
