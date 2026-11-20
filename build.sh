#!/usr/bin/env bash
set -e

PROJ="$(cd "$(dirname "$0")" && pwd)"
HEADER="$PROJ/components/header.html"
FOOTER="$PROJ/components/footer.html"
TMP="$PROJ/.build_tmp"
mkdir -p "$TMP"

# Inline SVG favicon as data URI
FAVICON_DATA="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 36 36'%3E%3Cpath d='M18 2L4 8v10c0 8.28 5.96 15.84 14 17.92C26.04 33.84 32 26.28 32 18V8L18 2z' fill='%231A2B5E'/%3E%3Crect x='12' y='16' width='12' height='9' rx='2' fill='%23F26B2A'/%3E%3Cpath d='M14 16v-3a4 4 0 018 0v3' stroke='%23F26B2A' stroke-width='2' fill='none'/%3E%3Ccircle cx='18' cy='20.5' r='1.5' fill='white'/%3E%3Crect x='17.5' y='20.5' width='1' height='2.5' rx='0.5' fill='white'/%3E%3C/svg%3E"

# ───────────────────────────────────────────────
# build_page <out_path> <title> <description> <canonical> <active_href>
#            <content_file> <extra_css> <jsonld_var> <depth>
# ───────────────────────────────────────────────
build_page() {
  local OUT="$1"
  local TITLE="$2"
  local DESC="$3"
  local CANONICAL="$4"
  local ACTIVE_HREF="$5"
  local CONTENT="$6"
  local EXTRA_CSS="$7"
  local JSONLD="$8"
  local DEPTH="$9"
  local OG_IMAGE="${10:-/images/og/home.png}"

  # depth-based relative base
  if [ "$DEPTH" = "0" ]; then
    BASE=""
    ROOT_HREF="./"
  else
    BASE=$(printf '../%.0s' $(seq 1 "$DEPTH"))
    ROOT_HREF="${BASE}"
  fi

  mkdir -p "$(dirname "$OUT")"
  TMP_HEADER="$TMP/header_tmp.html"
  TMP_FOOTER="$TMP/footer_tmp.html"
  TMP_CONTENT="$TMP/content_tmp.html"

  # Process header: inject active class + relativize paths
  # Active class only on plain nav <a href="..."> tags (not logo which has class= after href)
  sed \
    -e "s|href=\"${ACTIVE_HREF}\" class=\"site-logo\"|href=\"${ACTIVE_HREF}\" class=\"site-logo\"|g" \
    -e "s|href=\"${ACTIVE_HREF}\">|href=\"${ACTIVE_HREF}\" class=\"active\">|g" \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$HEADER" > "$TMP_HEADER"

  # Process footer: relativize paths
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$FOOTER" > "$TMP_FOOTER"

  # Process content: relativize paths
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$CONTENT" > "$TMP_CONTENT"

  # Build CSS link tags
  GLOBAL_CSS="${BASE}css/global.css"
  CSS_TAGS="<link rel=\"stylesheet\" href=\"${GLOBAL_CSS}\">"
  if [ -n "$EXTRA_CSS" ]; then
    CSS_TAGS="${CSS_TAGS}
    <link rel=\"stylesheet\" href=\"${BASE}css/${EXTRA_CSS}\">"
  fi

  # Build JSON-LD block
  JSONLD_BLOCK=""
  if [ -n "$JSONLD" ]; then
    JSONLD_BLOCK="<script type=\"application/ld+json\">${JSONLD}</script>"
  fi

  # Assemble page
  {
    cat <<HTMLHEAD
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${TITLE}</title>
  <meta name="description" content="${DESC}">
  <link rel="canonical" href="${CANONICAL}">
  <meta property="og:type" content="article">
  <meta property="og:title" content="${TITLE}">
  <meta property="og:description" content="${DESC}">
  <meta property="og:url" content="${CANONICAL}">
  <meta property="og:site_name" content="Best Cyber Security Companies">
  <meta property="og:image" content="https://best-cyber-security-companies.com${OG_IMAGE}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${TITLE}">
  <meta name="twitter:description" content="${DESC}">
  <meta name="twitter:image" content="https://best-cyber-security-companies.com${OG_IMAGE}">
  <link rel="icon" type="image/svg+xml" href="${FAVICON_DATA}">
  ${CSS_TAGS}
  ${JSONLD_BLOCK}
</head>
<body>
HTMLHEAD
    cat "$TMP_HEADER"
    cat "$TMP_CONTENT"
    cat "$TMP_FOOTER"
    cat <<HTMLFOOT
<script src="${BASE}js/nav.js" defer></script>
</body>
</html>
HTMLFOOT
  } > "$OUT"

  echo "  ✓ $OUT"
}

# ───────────────────────────────────────────────
# JSON-LD for index.html
# ───────────────────────────────────────────────
INDEX_JSONLD=$(cat <<'JSONLD'
[
 {
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Best Cyber Security Companies in UAE",
  "description": "Independent ranking of 12 UAE cybersecurity companies: pentesting, managed security, crypto forensics, compliance fit.",
  "url": "https://best-cyber-security-companies.com/",
  "mainEntityOfPage": "https://best-cyber-security-companies.com/",
  "inLanguage": "en",
  "datePublished": "2026-06-26",
  "dateModified": "2026-11-20",
  "image": "https://best-cyber-security-companies.com/images/og/home.png",
  "author": {
   "@type": "Organization",
   "name": "Editorial Team, Cyber Vendor Research",
   "url": "https://best-cyber-security-companies.com/about/"
  },
  "publisher": {
   "@type": "Organization",
   "name": "Best Cyber Security Companies",
   "url": "https://best-cyber-security-companies.com/"
  }
 },
 {
  "@context": "https://schema.org",
  "@type": "ItemList",
  "name": "Best Cyber Security Companies 2026",
  "description": "Independent ranking of 12 cybersecurity companies serving UAE clients, assessed on UAE regulatory fit, technical evidence, data handling and service depth.",
  "url": "https://best-cyber-security-companies.com/",
  "numberOfItems": 12,
  "itemListElement": [
   {
    "@type": "ListItem",
    "position": 1,
    "name": "Help AG",
    "url": "https://helpag.com"
   },
   {
    "@type": "ListItem",
    "position": 2,
    "name": "Paranoid Security",
    "url": "https://paranoid.security"
   },
   {
    "@type": "ListItem",
    "position": 3,
    "name": "Microminder Cyber Security",
    "url": "https://micromindercybersecurity.com"
   },
   {
    "@type": "ListItem",
    "position": 4,
    "name": "CPX",
    "url": "https://cpx.net"
   },
   {
    "@type": "ListItem",
    "position": 5,
    "name": "DTS Solution",
    "url": "https://dtssolution.com"
   },
   {
    "@type": "ListItem",
    "position": 6,
    "name": "CyberArrow",
    "url": "https://cyberarrow.io"
   },
   {
    "@type": "ListItem",
    "position": 7,
    "name": "Palo Alto Networks",
    "url": "https://paloaltonetworks.com"
   },
   {
    "@type": "ListItem",
    "position": 8,
    "name": "CrowdStrike",
    "url": "https://crowdstrike.com"
   },
   {
    "@type": "ListItem",
    "position": 9,
    "name": "Check Point Software",
    "url": "https://checkpoint.com"
   },
   {
    "@type": "ListItem",
    "position": 10,
    "name": "Fortinet",
    "url": "https://fortinet.com"
   },
   {
    "@type": "ListItem",
    "position": 11,
    "name": "IBM Security",
    "url": "https://ibm.com/security"
   },
   {
    "@type": "ListItem",
    "position": 12,
    "name": "Darktrace",
    "url": "https://darktrace.com"
   }
  ]
 },
 {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
   {
    "@type": "Question",
    "name": "Pentest or red teaming: which one do I need?",
    "acceptedAnswer": {
     "@type": "Answer",
     "text": "A penetration test looks for vulnerabilities in a defined set of systems and shows whether they can be exploited. A red team exercise is a stealthy attack towards a set goal that tests whether your detection works. Start with a pentest unless you already run a tested monitoring process."
    }
   },
   {
    "@type": "Question",
    "name": "Does every private company in Dubai need to follow DESC ISR?",
    "acceptedAnswer": {
     "@type": "Answer",
     "text": "No. DESC rules apply to Dubai government entities and organisations in scope of Dubai's information security framework, and Dubai government procurement often asks for accredited providers. Private companies outside that scope are not obliged to use an accredited provider, though some clients ask for one."
    }
   },
   {
    "@type": "Question",
    "name": "How often should we test?",
    "acceptedAnswer": {
     "@type": "Answer",
     "text": "At least once a year and after significant changes such as a new product, a major release or an infrastructure move. PCI DSS v4.x, for example, expects penetration testing at least once every 12 months and after significant changes. High-risk systems justify more frequent checks."
    }
   },
   {
    "@type": "Question",
    "name": "What is VARA and why does it matter when choosing a provider?",
    "acceptedAnswer": {
     "@type": "Answer",
     "text": "VARA is the Virtual Assets Regulatory Authority in Dubai. Its rulebooks set technology and information security expectations for licensed virtual asset firms, so those firms should confirm the current requirements and ask providers about relevant experience."
    }
   }
  ]
 },
 {
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Best Cyber Security Companies",
  "url": "https://best-cyber-security-companies.com/",
  "description": "Independent editorial ranking of cybersecurity companies for the UAE market."
 }
]
JSONLD
)

# ───────────────────────────────────────────────
# BUILD ALL PAGES
# ───────────────────────────────────────────────
echo "Building best-cyber-security-companies.com..."

build_page \
  "$PROJ/index.html" \
  "Best Cyber Security Companies 2026" \
  "Independent ranking of 12 UAE cybersecurity companies: pentesting, managed security, crypto forensics, compliance fit. Updated November 2026." \
  "https://best-cyber-security-companies.com/" \
  "/" \
  "$PROJ/content/main-ranking.html" \
  "home.css" \
  "$INDEX_JSONLD" \
  "0"

build_page \
  "$PROJ/methodology/index.html" \
  "Ranking Methodology | Best Cyber Security Companies" \
  "How we assess cybersecurity companies for the UAE market: regulatory fit, technical evidence and accreditation, data handling and locality, and service depth." \
  "https://best-cyber-security-companies.com/methodology/" \
  "/methodology/" \
  "$PROJ/content/methodology.html" \
  "home.css" \
  "" \
  "1"

build_page \
  "$PROJ/about/index.html" \
  "About | Best Cyber Security Companies" \
  "An independent editorial ranking for CISOs and IT directors evaluating cybersecurity vendors in the UAE. Editorial team of cybersecurity practitioners and compliance specialists." \
  "https://best-cyber-security-companies.com/about/" \
  "/about/" \
  "$PROJ/content/about.html" \
  "home.css" \
  "" \
  "1"

build_page \
  "$PROJ/editorial-policy/index.html" \
  "Editorial Policy | Best Cyber Security Companies" \
  "Our standards for inclusion, ranking criteria, conflict of interest policy, and update schedule for the cybersecurity company ranking." \
  "https://best-cyber-security-companies.com/editorial-policy/" \
  "/editorial-policy/" \
  "$PROJ/content/editorial-policy.html" \
  "home.css" \
  "" \
  "1"

build_page \
  "$PROJ/contact/index.html" \
  "Contact | Best Cyber Security Companies" \
  "Contact the editorial team for factual corrections, methodology questions, or general inquiries about the cybersecurity company ranking." \
  "https://best-cyber-security-companies.com/contact/" \
  "/contact/" \
  "$PROJ/content/contact.html" \
  "home.css" \
  "" \
  "1"

build_page \
  "$PROJ/submit-company/index.html" \
  "Submit Your Company | Best Cyber Security Companies" \
  "Submit your cybersecurity company for ranking consideration. We evaluate all submissions against our editorial methodology. Listing is editorial only — no paid placements." \
  "https://best-cyber-security-companies.com/submit-company/" \
  "/submit-company/" \
  "$PROJ/content/submit-company.html" \
  "home.css" \
  "" \
  "1"

# Guide pages: title/description from content/jsonld/<name>.meta, JSON-LD from content/jsonld/<name>.json
build_guide() {
  local NAME="$1" OUTDIR="$2" URLPATH="$3" DEPTH="$4" ACTIVE="${5:-/faq/}"
  local META="$PROJ/content/jsonld/${NAME}.meta"
  local G_TITLE G_DESC
  G_TITLE="$(sed -n 1p "$META")"
  G_DESC="$(sed -n 2p "$META")"
  build_page \
    "$PROJ/${OUTDIR}index.html" \
    "$G_TITLE" \
    "$G_DESC" \
    "https://best-cyber-security-companies.com${URLPATH}" \
    "$ACTIVE" \
    "$PROJ/content/${NAME}.html" \
    "home.css" \
    "$(cat "$PROJ/content/jsonld/${NAME}.json")" \
    "$DEPTH" \
    "/images/og/${NAME}.png"
}

build_guide "faq"                     "faq/"                              "/faq/"                              1
build_guide "faq-regulations"         "faq/regulations/"                  "/faq/regulations/"                  2
build_guide "faq-penetration-testing" "faq/penetration-testing/"          "/faq/penetration-testing/"          2
build_guide "faq-crypto"              "faq/crypto-and-virtual-assets/"    "/faq/crypto-and-virtual-assets/"    2
build_guide "faq-managed-security"    "faq/managed-security/"             "/faq/managed-security/"             2
build_guide "glossary"                "glossary/"                         "/glossary/"                         1 "/glossary/"

build_page \
  "$PROJ/cookie-policy/index.html" \
  "Cookie Policy | Best Cyber Security Companies" \
  "Cookie policy for best-cyber-security-companies.com. How we use cookies in compliance with UAE PDPL and GDPR." \
  "https://best-cyber-security-companies.com/cookie-policy/" \
  "/cookie-policy/" \
  "$PROJ/content/cookie-policy.html" \
  "home.css" \
  "" \
  "1"

# cleanup
rm -rf "$TMP"

echo ""
echo "Build complete. Pages:"
echo "  index.html"
echo "  methodology/index.html"
echo "  about/index.html"
echo "  editorial-policy/index.html"
echo "  contact/index.html"
echo "  submit-company/index.html"
echo "  faq/index.html (+4 sub-pages)"
echo "  glossary/index.html"
echo "  cookie-policy/index.html"
