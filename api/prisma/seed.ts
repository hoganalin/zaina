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

const seedAuthors = [
  { firebaseUid: 'seed-author-hana', nickname: 'Hana花子', city: 'Tokyo', country: 'Japan' },
  { firebaseUid: 'seed-author-marco', nickname: 'Marco紐約', city: 'New York', country: 'USA' },
  { firebaseUid: 'seed-author-lily', nickname: 'Lily倫敦', city: 'London', country: 'UK' },
  { firebaseUid: 'seed-author-sam', nickname: 'Sam雪梨', city: 'Sydney', country: 'Australia' },
  { firebaseUid: 'seed-author-jay', nickname: 'Jay坡縣', city: 'Singapore', country: 'Singapore' },
];

const postsByChannel: Record<string, Array<{ title: string; body: string }>> = {
  rent: [
    { title: '請問有人在中目黑租過 share house 嗎？', body: '看了一個 ¥85k 的位置，房東說只簽英文合約有點怕翻車，求踩雷或好評' },
    { title: 'Brooklyn 的 1bdr 真的快漲不動了', body: 'Bushwick 邊緣的一房一廳要 $2,400，比去年多 12%。有人成功談下來嗎？' },
    { title: 'East London 預算 £1,500/月夠嗎？', body: '想找 zone 2-3、走路到 tube 十分鐘內。房仲一直推 zone 4，但通勤成本要算進去' },
  ],
  secondhand: [
    { title: '出清搬家 — 整套 IKEA 沙發 + 茶几', body: '8 成新，自取 $200。下個月底搬去 LA，周末都在' },
    { title: '誰要這台 Dyson V8，便宜賣', body: '£60 成交，原廠配件齊全，倫敦市區可面交' },
    { title: '無印家具 sayonara sale', body: '床架、書桌、五斗櫃。下下週六之前要清掉，雪梨 Surry Hills 自取最划算' },
  ],
  ticket: [
    { title: 'Fuji Rock Day 2 兩張轉讓', body: '原價售出，朋友臨時不能去。詳情站內信，東京都內可面交' },
    { title: 'Hamilton Broadway 票一張', body: '本月 28 號晚場 orchestra row L，原價轉讓，無法去了' },
    { title: 'Wimbledon 第二週票需求', body: '想找 men\'s singles SF 一張，預算彈性可談，倫敦面交或寄送' },
  ],
  travel: [
    { title: '京都楓葉季哪個寺院最值得起早？', body: '11 月中下旬會去四天，想避開人潮拍照。永觀堂 vs. 東福寺 vs. 真如堂 三選一' },
    { title: 'NYC → Iceland 七天行程怎麼排', body: '想拍極光也想泡 Blue Lagoon，車要不要租？冰川上要走的路線安全嗎' },
    { title: '從倫敦怎麼最便宜飛回台灣', body: '七月寒假倒數，目前看到 £680 含一次轉機，有人撿到更便宜的嗎' },
  ],
  'travel-buddy': [
    { title: '九月底沖繩四天找旅伴', body: '預計女生兩位，浮潛 + 美食 + 拍照。已訂 Airbnb 一間還可加一個人' },
    { title: 'Banff 自駕誰要併車？', body: 'NYC 出發飛 Calgary，七天環露易絲湖 + Jasper。可以分擔油錢跟住宿' },
    { title: '冰島環島找第三人', body: '兩個倫敦女生七月底 ring road 十天，有興趣 DM 聊聊節奏跟預算' },
  ],
  food: [
    { title: '東京最被低估的拉麵店', body: '不是大行列那幾間。我自己最愛中野的「青葉」鶏白湯，湯頭乾淨不死鹹' },
    { title: 'Manhattan 哪裡有像台灣的早午餐', body: '想要那種有蛋餅、蘿蔔糕、豆漿的店。Flushing 太遠了，Manhattan 內有推薦嗎' },
    { title: '倫敦哪家鼎泰豐分店最對得起菜單', body: '上次 Centre Point 那間皮厚到難以下嚥。Selfridges 那間有好一點嗎？' },
  ],
  asia: [
    { title: '從東京搬去首爾，職場文化會差很多嗎', body: '日商三年了，最近有 offer 想跳。聽說韓國加班壓力反而更大？' },
    { title: '香港回流潮現在到哪了', body: '身邊金融業朋友最近三個月又有兩個跑去新加坡。倒是有人從新加坡回港的嗎' },
    { title: '台北到曼谷現在 digital nomad 友善嗎', body: '朋友三月去待一個月覺得簽證細節好複雜，想知道有沒有改' },
  ],
  spain: [
    { title: 'Barcelona 找西文家教（線上也可）', body: '已 B1 想衝 B2，想找母語人士一週兩次。預算 €25/小時上下' },
    { title: '馬德里租房可以不透過 Idealista 嗎', body: '看了一個月都搶不到，朋友說有 FB 社團。求路子' },
    { title: 'Sevilla 的 flamenco tablao 哪間最不觀光客', body: '不想踩到那種 €40 一杯難喝 sangria 的店，本地人去哪裡' },
  ],
  europe: [
    { title: '柏林冬天很憂鬱嗎', body: '從 Sydney 搬過去半年了，11 月開始日照少到我有點受不了。有人撐過來的經驗嗎' },
    { title: 'Amsterdam vs. Rotterdam 哪個適合 30 歲單身搬過去', body: '想要文化、工作機會、語言摩擦最低的組合' },
    { title: '葡萄牙 D7 簽證 2026 還好申請嗎', body: '聽說最近審慢很多，有人最近一年內順利下來的嗎' },
  ],
  'solo-travel': [
    { title: '獨自去京都吃 omakase 會尷尬嗎', body: '想去那種 8 個位子的 counter，怕格格不入。有過經驗的人怎麼處理小空檔' },
    { title: '一個女生去冰島自駕安全嗎', body: '十月底，環島八天。看了影片很心動但又怕路況', },
    { title: '獨自旅行最痛苦的時刻', body: '我自己是抵達當天 hotel check-in 後在房間呆呆坐著的那一小時。你們呢' },
  ],
  study: [
    { title: '美國 CS Master 申請現在還值得嗎', body: '已經工作五年。怕讀完再進職場 timing 不好，但又想要學位升級簽證' },
    { title: '英國一年 Master 是不是真的太短', body: '從錄取到畢業 14 個月。覺得學到東西但人際線斷得很快' },
    { title: '日本大學院文組獎學金路徑', body: 'MEXT 跟學校 fellowship 哪個比較好申請，誰能分享流程' },
  ],
  mood: [
    { title: '在國外過第一個沒有家人的中秋', body: '同事都覺得這只是個工作日。買了一塊月餅自己吃，突然很想哭' },
    { title: '回國一週又飛回倫敦的失落', body: '剛到希斯洛 immigration 排隊那段最難。有人跟我一樣嗎' },
    { title: '一個人在雪梨確診的那三天', body: '叫不到外送、沒人問你吃了沒、發燒到 39 度只能自己拿冰塊。後來反而成熟很多' },
  ],
};

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

  // Replace seed authors and their posts on every run.
  await prisma.post.deleteMany({
    where: { author: { firebaseUid: { startsWith: 'seed-author-' } } },
  });
  await prisma.user.deleteMany({
    where: { firebaseUid: { startsWith: 'seed-author-' } },
  });

  const createdAuthors = await Promise.all(
    seedAuthors.map((spec) =>
      prisma.user.create({
        data: {
          firebaseUid: spec.firebaseUid,
          nickname: spec.nickname,
          city: spec.city,
          country: spec.country,
          onboardingCompleted: true,
        },
      }),
    ),
  );

  const channelRows = await prisma.channel.findMany();
  const channelIdBySlug = new Map(channelRows.map((c) => [c.slug, c.id]));

  let postCount = 0;
  let rotation = 0;
  const baseTime = Date.now();
  for (const [slug, posts] of Object.entries(postsByChannel)) {
    const channelId = channelIdBySlug.get(slug);
    if (!channelId) continue;
    for (let i = 0; i < posts.length; i++) {
      const author = createdAuthors[rotation % createdAuthors.length];
      rotation += 1;
      // Stagger createdAt so list order is meaningful (newer posts first across the seed).
      const minutesAgo = postCount * 17;
      // Every post gets a deterministic Picsum photo. The card layer still
      // mixes templates per post.id hash, but at least every cell has
      // imagery so the wall doesn't feel bare.
      const imageUrl = `https://picsum.photos/seed/zaina-${postCount}/360/360`;
      await prisma.post.create({
        data: {
          authorId: author.id,
          channelId,
          title: posts[i].title,
          body: posts[i].body,
          city: author.city!,
          country: author.country!,
          imageUrl,
          createdAt: new Date(baseTime - minutesAgo * 60_000),
        },
      });
      postCount += 1;
    }
  }

  console.log(
    `Seeded ${channels.length} channels, ${interests.length} interests, ${createdAuthors.length} authors, ${postCount} posts.`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
