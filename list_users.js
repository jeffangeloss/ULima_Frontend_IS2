import postgres from 'postgres';

const sql = postgres("postgresql://uladmin:2026Ulima!@api-mobile-db.cbk2ge28uibe.us-east-2.rds.amazonaws.com:5432/postgres?sslmode=require");

async function run() {
  try {
    const users = await sql`
      select code, full_name, institutional_email
      from app_user
      limit 10
    `;
    console.log("Registered Users in Database:");
    console.log(JSON.stringify(users, null, 2));
  } catch (err) {
    console.error("Error querying database:", err);
  } finally {
    await sql.end();
  }
}

run();
