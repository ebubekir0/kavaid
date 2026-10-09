# Firebase kural dosyaları (eski kopyalar)

Bu klasördeki dosyalar proje kökünden buraya taşındı. **Hiçbiri otomatik olarak
yayınlanmıyor** (projede `firebase.json` yok) ve birbirleriyle çelişiyorlar:

| Dosya | İçerik |
|---|---|
| `firebase_database_rules.json` | Realtime Database: kökte `.read: true, .write: true` (herkese açık) |
| `firestore_security_rules.txt` | Firestore: `users` + `chats/general_chat` |
| `firestore_chat_rules.txt` | Firestore: `users` herkese okunur + `community_chat` |
| `chat_database_rules.txt` | Ayrı `chat-db` veritabanı için |

Ayrıca üst klasördeki (`kavaid1111/firestore.rules`) dosya da farklı bir sürüm.

Canlıdaki kurallar Firebase Console'da. Yapılması gereken: canlı kuralları
indirip tek bir `firestore.rules` / `database.rules.json` olarak buraya koymak,
`firebase.json` ile `firebase deploy --only firestore:rules,database`
üzerinden yönetmek ve bu eski kopyaları silmek.
