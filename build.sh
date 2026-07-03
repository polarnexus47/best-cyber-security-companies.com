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
    "@type": "ItemList",
    "name": "Best Cyber Security Companies 2026",
    "description": "Independent ranking of 12 cybersecurity companies evaluated on UAE compliance, CREST accreditation, sovereign SOC, and service depth.",
    "url": "https://best-cyber-security-companies.com/",
    "numberOfItems": 12,
    "itemListElement": [
      {"@type":"ListItem","position":1,"name":"Help AG","url":"https://helpag.com"},
      {"@type":"ListItem","position":2,"name":"Paranoid Security","url":"https://paranoid.security"},
      {"@type":"ListItem","position":3,"name":"Microminder Cyber Security","url":"https://micromindercybersecurity.com"},
      {"@type":"ListItem","position":4,"name":"CPX","url":"https://cpx.net"},
      {"@type":"ListItem","position":5,"name":"DTS Solution","url":"https://dtssolution.com"},
      {"@type":"ListItem","position":6,"name":"CyberArrow","url":"https://cyberarrow.io"},
      {"@type":"ListItem","position":7,"name":"Palo Alto Networks","url":"https://paloaltonetworks.com"},
      {"@type":"ListItem","position":8,"name":"CrowdStrike","url":"https://crowdstrike.com"},
      {"@type":"ListItem","position":9,"name":"Check Point Software","url":"https://checkpoint.com"},
      {"@type":"ListItem","position":10,"name":"Fortinet","url":"https://fortinet.com"},
      {"@type":"ListItem","position":11,"name":"IBM Security","url":"https://ibm.com/security"},
      {"@type":"ListItem","position":12,"name":"Darktrace","url":"https://darktrace.com"}
    ]
  },
  {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": [
      {
        "@type": "Question",
        "name": "What is the difference between penetration testing and red teaming?",
        "acceptedAnswer": {"@type": "Answer", "text": "Penetration testing enumerates vulnerabilities within a defined scope over a fixed timeframe. Red teaming simulates a real adversary pursuing a specific objective without predefined scope, testing detection and response capability."}
      },
      {
        "@type": "Question",
        "name": "Is DESC ISR V3 compliance mandatory for private companies in Dubai?",
        "acceptedAnswer": {"@type": "Answer", "text": "DESC ISR V3 is mandatory for all Dubai Government and semi-government entities and their technology vendors. Private companies with no government contracts are not legally required to comply."}
      },
      {
        "@type": "Question",
        "name": "What does UAE PDPL require from cybersecurity vendors?",
        "acceptedAnswer": {"@type": "Answer", "text": "UAE PDPL requires that PII of UAE residents be processed and stored on UAE soil. Cybersecurity vendors must not route log data through offshore data centers, and breach notification is mandatory within 72 hours."}
      },
      {
        "@type": "Question",
        "name": "How often should a company conduct penetration testing in the UAE?",
        "acceptedAnswer": {"@type": "Answer", "text": "DESC ISR V3 and NESA require annual testing. VARA requires annual penetration tests for licensed VASPs. PCI DSS requires annual pentest plus quarterly vulnerability scanning."}
      },
      {
        "@type": "Question",
        "name": "What is VARA and why does it affect cybersecurity vendor selection?",
        "acceptedAnswer": {"@type": "Answer", "text": "VARA is Dubai's regulator for virtual asset service providers. VARA licensing requires annual penetration testing, an incident response plan, AML controls, and blockchain forensics capability."}
      },
      {
        "@type": "Question",
        "name": "What is blockchain forensics and when is it needed?",
        "acceptedAnswer": {"@type": "Answer", "text": "Blockchain forensics investigates cryptocurrency transactions to trace fund movement and build court-admissible evidence chains. It is required for crypto hacks, VARA compliance, and law enforcement cases."}
      },
      {
        "@type": "Question",
        "name": "What is a sovereign SOC and why does UAE law require it?",
        "acceptedAnswer": {"@type": "Answer", "text": "A sovereign SOC processes all security data within UAE national territory with no offshore data transit. UAE PDPL and DESC ISR V3 require this architecture for regulated organizations."}
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
  "Independent ranking of the top 12 cybersecurity companies for 2026. Evaluated by UAE compliance, CREST accreditation, sovereign SOC capabilities and service depth." \
  "https://best-cyber-security-companies.com/" \
  "/" \
  "$PROJ/content/main-ranking.html" \
  "home.css" \
  "$INDEX_JSONLD" \
  "0"

build_page \
  "$PROJ/methodology/index.html" \
  "Ranking Methodology | Best Cyber Security Companies" \
  "How we evaluate and rank cybersecurity companies for the UAE market. Five weighted criteria: UAE presence, regulatory compliance, sovereign SOC, accreditation, and service depth." \
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

build_page \
  "$PROJ/faq/index.html" \
  "FAQ — Cybersecurity in UAE | Best Cyber Security Companies" \
  "Answers to common questions about cybersecurity vendors, UAE regulations (PDPL, DESC, VARA, NESA), penetration testing, and how to choose a security partner." \
  "https://best-cyber-security-companies.com/faq/" \
  "/faq/" \
  "$PROJ/content/faq.html" \
  "home.css" \
  "" \
  "1"

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
echo "  faq/index.html"
echo "  cookie-policy/index.html"
