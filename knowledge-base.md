# Dev Knowledge Base

> Živý dokument. Aktualizuje se po každém projektu kdy přibyde ověřený poznatek.
> Poslední aktualizace: duben 2026 (rezervace-app vlákno 01–07, architektonické principy)
> Autor: Milan Trnka + Claude (Anthropic AI)

---

## Obsah

1. [Principy práce s AI](#1-principy-práce-s-ai)
2. [Git workflow](#2-git-workflow)
3. [PowerShell — kritické problémy](#3-powershell--kritické-problémy)
4. [Cloudflare Workers + Pages](#4-cloudflare-workers--pages)
5. [Supabase — databáze a auth](#5-supabase--databáze-a-auth)
6. [API klíče — správa a bezpečnost](#6-api-klíče--správa-a-bezpečnost)
7. [Platby — bankovní integrace](#7-platby--bankovní-integrace)
8. [Email — transakční odesílání](#8-email--transakční-odesílání)
9. [Autentizace a role](#9-autentizace-a-role)
10. [Frontend — Astro specifika](#10-frontend--astro-specifika)
11. [Deployment workflow](#11-deployment-workflow)
12. [Architektura — obecné principy](#12-architektura--obecné-principy)
13. [Modulární architektura — loose coupling](#13-modulární-architektura--loose-coupling)

---

## 1. Principy práce s AI

### Role AI v projektu

AI vystupuje jako:
- **Architekt** — navrhuje strukturu, předvídá problémy
- **Senior specialista** — upozorní i bez ptaní, zná known issues
- **Designér řešení** — hledá nejefektivnější cestu, ne první funkční

AI neslepě plní zadání. Pokud vidí problém nebo lepší cestu — řekne to. Vývojář má vždy poslední slovo.

### Klíčové omezení

AI nezná skutečný stav repozitáře. Pracuje pouze s textem v aktuální konverzaci. Proto:

- Vždy poskytnout aktuální verzi souboru před editací: *"Toto je aktuální stav, ignoruj předchozí návrhy"*
- Nikdy nepředpokládat, že AI pamatuje co bylo domluveno dříve
- Vývojář zůstává architektem — AI je nástroj

### Jak zadávat úkoly

```
❌ "Přidej export."
✅ "Uživatel potřebuje stáhnout data offline. Jak to nejlépe řešit?"
```

Říkat PROČ, ne jen CO. AI navrhne lepší řešení když zná záměr.

Explicitně vymezit hranice:
```
Změň pouze funkci exportData().
Nesahej na importData() ani na žádnou jinou část souboru.
```

### Minimální změna — povinný postup

1. Přečíst aktuální stav souboru — nikdy nepsat z paměti
2. Explicitně pojmenovat co se mění a co se nesmí změnit
3. Provést minimální opravu — žádný refactoring navíc
4. Potvrdit: *"Změnil jsem pouze X. Funkce Y zůstala nedotčena ✅"*

### Délka konverzace

Po ~40–60 zprávách model začíná míchat kontext. Začít novou konverzaci když:
- Pracujeme na jiném modulu
- AI navrhuje věci které byly dříve zamítnuty
- Po každém větším milníku

### Jednoduché vždy vyhrává

```
Jednoduché > Chytré > Komplexní
```

Nejlepší kód řeší problém co nejjednodušeji. AI nepřidává složitost jen proto, že může.

---

## 2. Git workflow

### Povinný postup po každé změně

```powershell
git add <soubory>
git commit --allow-empty -m "stručný popis"
git push
git log --oneline -3    # zkontrolovat a zapsat hash
```

`--allow-empty` zajistí commit i když nejsou změny (předejde chybě "nothing to commit").

### Commit vždy zahrnuje aktualizaci dokumentace

Před každým commitem:
- Aktualizovat projektovou dokumentaci
- Zvážit jestli přibyl poznatek hodný knowledge base

### Konvence commit zpráv

```
feat: nová funkce
fix: oprava chyby
refactor: refactoring bez změny funkce
docs: pouze dokumentace
wip: rozpracováno
```

### Při regresi

```
"Funkce X přestala fungovat. Naposledy fungovala v commitu abc1234."
```

AI pak vytáhne přesnou funkci: `git show abc1234:src/soubor.js`

### Known Good zápisník

Udržovat `known_good.md` v projektu:
```markdown
## Login
✅ abc1234 — login, logout, session fungují

## Export
✅ def5678 — export JSON, správné názvy souborů
```

Zapisovat až po otestování — ne jen po commitu.

### Dva repozitáře najednou

```powershell
# Skript commit-all.ps1
cd D:\git\<projekt>
git add .
git commit --allow-empty -m $msg
git push

cd D:\git\dev-knowledge-base
git add knowledge-base.md
git commit --allow-empty -m "update: poznatky z $projekt"
git push
```

---

## 3. PowerShell — kritické problémy

### UTF-8 a diakritika — KRITICKÝ PROBLÉM

PowerShell here-string (`@"..."@`) poškozuje UTF-8 znaky při zápisu do souborů. Výsledkem jsou `\ufffd` znaky nebo `??` v HTML.

**Pravidlo:** Nikdy nepsat česky přímo do PowerShell příkazů nebo here-strings.

### Ověřené řešení podle situace

| Úkol | Nástroj |
|------|---------|
| Zápis nových souborů s češtinou | Node `.cjs` s `\uXXXX` escape sekvencemi |
| Oprava existujících souborů | Python skript (`encoding='utf-8'`) |
| Ověření obsahu souboru | `python -c "print(open(f, encoding='utf-8').read()[:300])"` |

**Zápis přes Node .cjs:**
```javascript
// fix.cjs
const fs = require('fs');
// Nikdy přímá čeština — vždy \uXXXX
const content = 'N\u00e1zev: P\u0159\u00edkladov\u00e1 aplikace';
fs.writeFileSync('output.txt', content, 'utf8');
```

**Oprava přes Python:**
```powershell
@'
c = open('soubor.astro', encoding='utf-8').read()
c = c.replace('spatny_text', 'Správný text')
open('soubor.astro', 'w', encoding='utf-8').write(c)
'@ | Set-Content fix.py
python fix.py
```

**Pozor:** Single-quote `@'...'@` — zabrání interpretaci `$` a backtick. Double-quote `@"..."@` interpretuje PS proměnné — backticky se rozbijí.

### Ověření obsahu

Terminál (`type`, PS výstup) zobrazuje UTF-8 špatně — to NEZNAMENÁ poškozený soubor. Python zobrazuje správně:

```powershell
python -c "print(open('soubor.astro', encoding='utf-8').read()[:300])"
```

### Out-File varování

`Out-File -Encoding utf8` přidává BOM. Bezpečnější alternativa:
```python
open(f, 'w', encoding='utf-8').write(content)  # bez BOM
```

---

## 4. Cloudflare Workers + Pages

### Architektura

```
Cloudflare Pages (frontend — Astro)
    ↓ Service Bindings (ne HTTP!)
Cloudflare Workers (API)
    ↓ REST API
Supabase (databáze)
```

### Service Bindings — KRITICKÉ

HTTP volání mezi workery na `*.workers.dev` jsou **blokovaná**. Používat Service Bindings.

```toml
# wrangler.toml
[[services]]
binding = "SVC_ADMIN_API"
service = "admin-api"
```

```typescript
// Správně — Service Binding
const response = await env.SVC_ADMIN_API.fetch(request);

// Špatně — HTTP volání (blokované)
const response = await fetch('https://admin-api.bass443.workers.dev/...');
```

### Secrets management

```powershell
cd workers/<nazev-workeru>
npx wrangler secret put NAZEV_KLICE   # interaktivní zadání
npx wrangler secret list              # výpis názvů (ne hodnot!)
npx wrangler deploy                   # redeploy po změně secrets
```

**Pozor:** Hodnoty secrets nelze zpětně přečíst. Při ztrátě nutno vygenerovat nové.

### Cron Workers

```toml
# wrangler.toml
[triggers]
crons = ["*/5 * * * *"]   # každých 5 minut
```

Cron Worker na Supabase free tier: minimálně každých 5 minut = prevence pauzy projektu po neaktivitě.

### Env interface (TypeScript)

Každý secret musí být deklarován v `Env` interface:

```typescript
export interface Env {
  SUPABASE_SERVICE_KEY: string;
  RESEND_API_KEY: string;
  FIO_PLATFORM_TOKEN: string;
  ENCRYPTION_KEY: string;
  INTERNAL_AUTH_TOKEN: string;
}
```

### Nasazení

```powershell
cd workers/<nazev>
npm install
npx wrangler deploy
```

### Inter-worker autentizace

Pro worker-to-worker komunikaci přes Service Bindings: `INTERNAL_AUTH_TOKEN` jako Bearer token. Libovolný řetězec (doporučeno UUID nebo 64+ znaků).

---

## 5. Supabase — databáze a auth

### RLS + JWT — KRITICKÉ

Workers musí předávat **uživatelův Bearer token**, ne service key, aby `auth.uid()` správně fungovalo pod RLS.

```typescript
// ŠPATNĚ — service key nesetuje auth.uid(), RLS selže
headers: { "Authorization": `Bearer ${env.SUPABASE_SERVICE_KEY}` }

// SPRÁVNĚ — uživatelův JWT setuje auth.uid()
headers: { "Authorization": `Bearer ${userToken}` }
```

Service key používat jen pro operace které záměrně obchází RLS (cron jobs, billing, párování plateb).

### RLS povinnost

Každá tabulka musí mít RLS enabled. Bez RLS jsou data přístupná přes anon key.

```sql
ALTER TABLE nazev_tabulky ENABLE ROW LEVEL SECURITY;
```

Kontrola:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

### Helper funkce (public schema)

```sql
public.is_superadmin()       -- ověří roli superadmin
public.get_user_role()       -- vrátí roli přihlášeného uživatele
public.get_user_tenant_id()  -- vrátí tenant_id přihlášeného uživatele
```

### Multi-tenant pattern

```sql
-- RLS politika — tenant vidí pouze svá data
CREATE POLICY "tenant_isolation" ON tabulka
  FOR ALL USING (tenant_id = public.get_user_tenant_id());
```

### Migrace — konvence

```
supabase/migrations/
├── 001_init.sql      -- schéma tabulek
├── 002_rls.sql       -- Row Level Security pravidla
└── 003_seed.sql      -- testovací data
```

### Supabase JWT platnost

JWT token platí **1 hodinu** (3600s). Po expiraci nutné nové přihlášení. Ukládat v `localStorage` pod konzistentním klíčem.

### Nový formát klíčů (2025+)

- Anon key: `sb_pub...` (dříve `eyJ...`)
- Service key: `sb_sec...` (dříve `eyJ...`)

### Resetování hesla přes SQL

Pokud chybí tlačítko v UI:
```sql
UPDATE auth.users
SET encrypted_password = crypt('NoveHeslo123!', gen_salt('bf'))
WHERE id = 'uuid-uzivatele';
```

### Free tier — prevence pauzy

Projekt se pozastaví po 7 dnech neaktivity. Řešení: cron Worker volající DB každých 5 minut.

---

## 6. API klíče — správa a bezpečnost

### Zásady

1. Nikdy ukládat klíče do kódu ani `.env` v repozitáři
2. Cloudflare Worker Secrets = primární úložiště pro Workers
3. Service key (Supabase) obchází RLS — pouze backend Workers
4. Frontend smí používat pouze anon key

### Šifrování v databázi — AES-256-GCM

Pro ukládání klíčů třetích stran do DB (Fio token tenantů apod.):

```typescript
// crypto.ts — Web Crypto API
async function encrypt(plaintext: string, base64Key: string): Promise<{encrypted: string, iv: string}> {
  const key = await getKey(base64Key);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plaintext);
  const encrypted = await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, encoded);
  return {
    encrypted: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv))
  };
}
```

Šifrovací klíč jako Cloudflare Worker Secret:
```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
npx wrangler secret put ENCRYPTION_KEY
```

**Pozor:** Bez `ENCRYPTION_KEY` jsou data v DB nečitelná. Při ztrátě nutno přegenerovat a znovu uložit všechny klíče.

### Tabulka system_settings (šifrované klíče)

```sql
CREATE TABLE system_settings (
  key TEXT PRIMARY KEY,
  encrypted_value TEXT NOT NULL,
  iv TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by TEXT
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_only" ON system_settings
  FOR ALL USING (auth.role() = 'service_role');
```

### resolveApiKeys() pattern

Worker čte klíče z DB (dešifruje), s fallbackem na env proměnné. In-memory cache (5min TTL) pro výkon:

```typescript
let cache: Record<string, string> | null = null;
let cacheExpiry = 0;

async function resolveApiKeys(env: Env): Promise<Record<string, string>> {
  if (cache && Date.now() < cacheExpiry) return cache;
  // načíst z DB, dešifrovat...
  cacheExpiry = Date.now() + 5 * 60 * 1000;
  return cache;
}
```

### Typy klíčů a jejich specifika

| Klíč | Expiruje? | Riziko při expiraci |
|------|-----------|---------------------|
| Supabase service key | Ne | Nízké |
| Resend API key | Ne | Nízké |
| Fio platform token | ⚠️ Možná | **Vysoké** — tiché selhání párování plateb |
| Interní auth token | Ne | Nízké |

**Fio token** je jediný s rizikem tiché expirace — kontrolovat minimálně týdně.

### Kontrola platnosti klíčů

Udržovat `check-api-keys.ps1` v root projektu. Spouštět minimálně 1× týdně, u Fio tokenu ideálně denně.

---

## 7. Platby — bankovní integrace

### Fio banka — variable symbol pattern

Každá rezervace dostane unikátní variabilní symbol (VS). Platba je spárována s rezervací podle VS.

```
Zákazník → zadá VS do platebního příkazu → Fio API vrátí transakce → párování dle VS → aktualizace stavu
```

### Fio API — rate limit

**1 request / 30 sekund** — kritické pro design pollingu a testování.

```typescript
// Správný endpoint pro historické transakce
GET https://fioapi.fio.cz/v1/rest/periods/{token}/{date_from}/{date_to}/transactions.json
```

### Polling pattern (cron Worker)

```
fio-polling: každých 5 minut
1. Načte aktivní tenanty s fio_api_token
2. Pro každého tenantu zavolá Fio API (posledních 7 dní)
3. Pro každou transakci s VS najde rezervaci ve stavu "čeká"
4. Ověří částku (tolerance ±1 Kč)
5. Aktualizuje stav: čeká → zaplaceno
6. Zapíše do billing_log
7. Odešle vstupenku emailem
```

### Billing tenantů (SaaS model)

```
fio-billing: každých 6 hodin
- 7 dní před expirací: upozornění emailem
- Expirace: plan_status = grace (7 dní na doplacení)
- Po grace: plan_status = deactivated, aktivni = false
```

Párování plateb tenantů podle částky:
```
490 Kč  → monthly (30 dní)
4490 Kč → annual (365 dní)
```

### Duplicitní platby

Detekovat: pokud VS je již označen jako zaplacený → zapsat upozornění do Event Log, nezdvojit stav.

### Fio token — per tenant vs. platform

Dva různé účty:
- **Platform token** — příchozí platby za předplatné tenantů
- **Tenant token** — příchozí platby zákazníků za rezervace (uložen v `tenants.fio_api_token`, šifrovaný)

---

## 8. Email — transakční odesílání

### Resend — setup

```
resend.com → API Keys → Create (restricted: pouze odesílání)
```

Klíč formát: `re_...`

### Ověření domény — BLOKUJÍCÍ KROK

Bez ověřené domény nelze odesílat. Postup:

1. resend.com/domains → přidat doménu
2. Resend vygeneruje DNS záznamy (SPF, DKIM, DMARC)
3. Přidat záznamy v Cloudflare DNS
4. Verify v Resend
5. Počkat na propagaci (minuty až hodiny)

**Pozor:** Toto je nejčastější příčina proč emaily nefungují při prvním nastavení.

### Test klíče bez ověřené domény

Klíč je platný i když doména není ověřená — test vrátí `validation_error`, ne `401`:

```powershell
# validation_error = klíč OK, doména neověřená
# 401 = neplatný klíč
```

### Typy emailů v rezervačním systému

- Vstupenka zákazníkovi (po zaplacení)
- Upozornění na expiraci předplatného (7 dní před)
- Billing potvrzení tenantovi

---

## 9. Autentizace a role

### Role model (superadmin / admin / keyuser)

```
superadmin → správa celé platformy (všichni tenanti)
admin      → správa vlastního tenantu
keyuser    → check-in vstupenek, přehled rezervací na akci
```

### Auth flow v Worker

```typescript
// 1. Klient pošle Bearer JWT
// 2. Worker ověří přes Supabase Auth
const { data: { user } } = await supabase.auth.getUser(token);
// 3. Načte profil pomocí uživatelova JWT (ne service key!)
const profile = await fetchWithUserToken('/rest/v1/profiles', token);
// 4. RLS políčka fungují správně protože auth.uid() je nastaven
```

### requireRole() pattern

```typescript
async function requireSuperadmin(token: string, env: Env) {
  const user = await getUser(token, env);
  if (!user || user.role !== 'superadmin') {
    throw new Response('Forbidden', { status: 403 });
  }
  return user;
}
```

### Tabulka profilů

```sql
CREATE TABLE profily (
  id UUID REFERENCES auth.users PRIMARY KEY,
  tenant_id UUID REFERENCES tenants,
  role TEXT CHECK (role IN ('superadmin', 'admin', 'keyuser'))
);
```

---

## 10. Frontend — Astro specifika

### Inline skripty

```html
<!-- ŠPATNĚ — Astro bundluje, import.meta.env nefunguje -->
<script src="/lang.js"></script>

<!-- SPRÁVNĚ — is:inline zabrání bundlování -->
<script src="/lang.js" is:inline></script>
```

### Event listenery

```javascript
// ŠPATNĚ — onclick nefunguje v Astro kompilovaných stránkách
<button onclick="login()">

// SPRÁVNĚ
<button id="btn">
document.getElementById("btn").addEventListener("click", login);
```

### import.meta.env v inline scriptech

Nefunguje. Alternativy:
- Hardcoded URL (pro veřejné endpointy)
- `<script is:inline>` s předanými hodnotami přes data atributy

### i18n architektura

```
src/lib/i18n.ts     — slovník překladů (server-side, TypeScript)
public/lang.js      — runtime překlady (client-side, vanilla JS)
data-i18n="klic"    — atribut na HTML elementech
window.t('klic')    — pro JS-generovaný obsah
localStorage('lang') — uložení preference jazyka
```

Přepínač jazyka: text CS/EN (ne vlajky emoji — nefungují spolehlivě na Windows).

### Dynamický obsah (JS generated)

```javascript
// ŠPATNĚ — hardcoded čeština
tbody.innerHTML = '<tr><td>Žádné záznamy</td></tr>';

// SPRÁVNĚ
tbody.innerHTML = '<tr><td>' + window.t('noData') + '</td></tr>';
```

---

## 11. Deployment workflow

### Cloudflare Pages — automatické nasazení

Push do `main` větve → automatický build a deploy na Pages.

### Lokální vývoj

```powershell
cd workers/<nazev>
npx wrangler dev          # lokální Worker
```

### Struktura projektu (doporučená)

```
projekt/
├── supabase/migrations/     # SQL migrace (001_init, 002_rls, 003_seed)
├── workers/
│   ├── <worker-name>/
│   │   ├── src/
│   │   │   ├── index.ts     # hlavní handler
│   │   │   ├── auth.ts      # autentizace + Env interface
│   │   │   └── crypto.ts    # šifrování (pokud potřeba)
│   │   └── wrangler.toml
│   └── ...
├── frontend/                # Astro
│   ├── src/
│   │   ├── lib/
│   │   │   ├── i18n.ts
│   │   │   └── supabase.ts
│   │   └── pages/
│   └── public/
│       └── lang.js
├── docs/                    # dokumentace
├── check-api-keys.ps1       # kontrola klíčů
├── known_good.md            # validované commity
└── README.md
```

### Health endpointy

Každý Worker by měl implementovat `GET /health`:

```typescript
if (path === '/health') {
  return new Response(JSON.stringify({ status: 'ok', worker: 'nazev-workeru' }), {
    headers: { 'Content-Type': 'application/json' }
  });
}
```

Umožňuje system-check endpoint a monitoring.

---

## 12. Architektura — obecné principy

### Jeden soubor, jedna odpovědnost

Největší zdroj regresí je velký monolitický soubor. Při editaci jedné části AI neúmyslně přepíše jinou.

```
src/
  components/    ← každá komponenta zvlášť
  hooks/         ← každý hook zvlášť
  services/      ← volání API a business logika
  utils/         ← pomocné funkce
```

U souborů nad ~700 řádků: posílat AI pouze konkrétní funkci + 20–40 řádků kontextu.

### Perzistence dat patří do databáze

Jakýkoliv stav který musí přežít zavření prohlížeče nebo být dostupný na více zařízeních → databáze, ne localStorage.

### Relační rozšíření místo monolitu

Místo jedné velké tabulky s mnoha nullable sloupci: základní tabulka + rozšiřující tabulky podle typu.

```sql
-- Místo: produkty (nazev, cena, kapacita, datum_akce, isbn, ...)
-- Lépe:
produkty (id, nazev, cena, typ)
akce (produkt_id, kapacita, datum)      -- jen pro typ=akce
knihy (produkt_id, isbn, autor)         -- jen pro typ=kniha
```

### Plovoucí prvky mimo transformované kontejnery

Pokud rodičovský element používá CSS transformaci (scale, translate), `position: fixed` u potomka ztratí fixní chování. Modály a overlaye renderovat na nejvyšší úrovni stromu.

### Názvy souborů bez národních znaků

Exportované soubory pojmenovávat pouze ASCII — háčky, čárky a mezery způsobují problémy napříč OS a prohlížeči.

### Nativní znaky místo HTML entit v šablonách

JSX, Astro, Vue templates: používat přímo Unicode znaky nebo emoji, ne HTML entity.

### Checklist před každým commitem

- [ ] Přečten aktuální stav souboru (ne z paměti)
- [ ] Zadání obsahovalo PROČ, ne jen CO
- [ ] Změněno POUZE co bylo požadováno — žádný refactoring navíc
- [ ] AI potvrdila které části zůstaly nedotčeny
- [ ] Bug byl reprodukovatelný před opravou
- [ ] Výstup byl ověřen funkčně
- [ ] Perzistentní data jdou do databáze
- [ ] `git commit --allow-empty` použit
- [ ] `git log --oneline -3` zkontrolován
- [ ] Validovaný hash zapsán do `known_good.md`
- [ ] Dokumentace aktualizována

---

## 13. Modulární architektura — loose coupling

### Základní princip

Každý modul musí být schopen fungovat samostatně. Pokud jeden modul selže, ostatní pokračují.

```
❌ Modul A volá interní funkci Modulu B
✅ Modul A volá definované rozhraní (API endpoint, DB tabulka, event)
```

### Failure mode — povinná definice

Každý modul musí mít definovaný failure mode: co se stane když selže závislost?

**Vedlejší operace nikdy nesmí blokovat hlavní flow:**

```typescript
// ŠPATNĚ — email blokuje billing
await processBilling(tenant);
await sendEmail(tenant);          // pokud selže → billing se tváří jako chyba

// SPRÁVNĚ — email je vedlejší, billing proběhne vždy
await processBilling(tenant);
try {
  await sendEmail(tenant);
} catch (err) {
  await logError('email_failed', err);  // tiché selhání, zalogovat
}
```

### Hierarchie závislostí

```
Kritické (musí fungovat):
  └── databáze, hlavní business logika

Důležité (degradovaný stav bez nich):
  └── platební párování, auth

Vedlejší (tiché selhání OK):
  └── email notifikace, event log, image optimizer
```

### Praktické příklady

| Situace | Správné chování |
|---------|-----------------|
| Resend nefunguje | Billing proběhne, email se nezašle, zaloguje se |
| image-optimizer nefunguje | Akce se zobrazí bez obrázku |
| Event Log selže | Hlavní operace proběhne, log se nezapíše |
| fio-polling selže | Rezervace stále přijímá objednávky, párování počká |

### Komunikace mezi moduly

Moduly spolu komunikují přes:
- **REST API endpoint** (definovaný kontrakt)
- **Databázová tabulka** (sdílená data)
- **Event / log záznam** (asynchronní notifikace)

Ne přímým voláním interních funkcí jiného modulu.

### Health check jako standard

Každý modul implementuje `GET /health` — umožňuje centrální monitoring bez závislosti na implementaci:

```typescript
if (path === '/health') {
  return Response.json({ status: 'ok', module: 'nazev', timestamp: new Date().toISOString() });
}
```

### Graceful degradation v UI

Frontend musí počítat s tím, že backend modul neodpovídá:

```javascript
// Vždy ošetřit timeout a chybu — zobrazit degradovaný stav, ne prázdnou stránku
try {
  const data = await fetchWithTimeout(url, 5000);
  renderData(data);
} catch {
  renderFallback();   // zobrazit cached data nebo prázdný stav s vysvětlením
}
```

---

*Repozitář: github.com/Anamax443/dev-knowledge-base*
*Projekt odkud pochází první verze: github.com/Anamax443/rezervace-app*
