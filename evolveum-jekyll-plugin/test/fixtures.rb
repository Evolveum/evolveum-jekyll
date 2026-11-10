BASE_PAGES = {
  "/iam/" => { "title" => "Identity and Access Management", "display-order" => 50 },
  "/iam/ldap/" => { "title" => "LDAP" },
  "/midpoint/" => { "title" => "MidPoint", "display-order" => 200 },
  "/midpoint/guides/" => { "title" => "Guides" },
  "/midpoint/guides/a/" => { "title" => "A" },
  "/midpoint/guides/b/" => { "title" => "B", "visibility" => "hidden" },
  "/midpoint/release/" => { "title" => "Releases" },
  "/legal/" => { "title" => "Legal", "visibility" => "hidden" }
}.freeze

SECTION_PAGES = BASE_PAGES.merge(
  "/midpoint/reference/" => { "title" => "Reference", "nav-section" => true },
  "/midpoint/reference/master/" => { "title" => "Development" },
  "/legal/terms/" => { "title" => "Terms" },
  "/404.html" => { "title" => "Not found" }
).freeze
