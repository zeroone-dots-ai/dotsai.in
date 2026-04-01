import type { Metadata } from "next";
import { Instrument_Serif, DM_Sans, Space_Mono } from "next/font/google";
import "./globals.css";

const instrumentSerif = Instrument_Serif({
  weight: "400",
  subsets: ["latin"],
  variable: "--font-instrument-serif",
  display: "swap",
});

const dmSans = DM_Sans({
  subsets: ["latin"],
  variable: "--font-dm-sans",
  display: "swap",
});

const spaceMono = Space_Mono({
  weight: ["400", "700"],
  subsets: ["latin"],
  variable: "--font-space-mono",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://dotsai.in"),
  title: "ZeroOne D.O.T.S AI | Best AI Agency in Gurugram, India",
  description:
    "Best AI agency in Gurugram by Meet Deshani. Founder-led private AI deployment, AI automation, GEO, and premium AI web systems for enterprises in Gurugram, Delhi NCR and across India.",
  keywords: [
    "AI agency Gurugram", "best AI agency Gurugram", "best AI agency in Gurugram",
    "AI automation Gurugram", "AI consultant Gurugram", "AI consultant Gurgaon",
    "AI agency India", "private AI agency", "private AI", "on-premise AI",
    "AI deployment", "custom AI agents", "enterprise AI", "AI consultant India",
    "ZeroOne DOTS AI", "Meet Deshani", "local LLM", "private LLM deployment",
    "AI automation", "GEO AI", "AI web development India",
  ],
  authors: [{ name: "Meet Deshani", url: "https://dotsai.in" }],
  creator: "Meet Deshani",
  openGraph: {
    title: "ZeroOne D.O.T.S AI | Best AI Agency in Gurugram, India",
    description:
      "Best AI agency in Gurugram. Founder-led private AI deployment, AI automation, GEO, and premium AI web systems for businesses in Gurugram, Delhi NCR and India.",
    url: "https://dotsai.in",
    siteName: "ZeroOne D.O.T.S AI",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "ZeroOne D.O.T.S AI" }],
    locale: "en_IN",
  },
  twitter: {
    card: "summary_large_image",
    title: "ZeroOne D.O.T.S AI | Best AI Agency in Gurugram, India",
    description: "Best AI agency in Gurugram. Private AI deployment, AI automation, GEO, and premium AI web systems by Meet Deshani.",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, "max-image-preview": "large" },
  },
  alternates: { canonical: "https://dotsai.in" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html
      lang="en"
      className={`${instrumentSerif.variable} ${dmSans.variable} ${spaceMono.variable}`}
    >
      <head>
        <link rel="icon" type="image/svg+xml" href="/brand/zeroone-dark-icon.svg" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@graph": [
                {
                  "@type": "Organization",
                  "@id": "https://dotsai.in/#organization",
                  name: "ZeroOne D.O.T.S AI",
                  url: "https://dotsai.in",
                  logo: "https://dotsai.in/favicon.svg",
                  description:
                    "Best AI agency in Gurugram, India. Founder-led private AI agency focused on private AI systems, AI automation, GEO, and AI-enabled web experiences.",
                  areaServed: [
                    { "@type": "City", name: "Gurugram" },
                    { "@type": "City", name: "New Delhi" },
                    { "@type": "Country", name: "India" },
                  ],
                  founder: {
                    "@type": "Person",
                    "@id": "https://dotsai.in/#meet",
                    name: "Meet Deshani",
                  },
                  contactPoint: {
                    "@type": "ContactPoint",
                    contactType: "Business Inquiries",
                    url: "https://wa.me/918320065658",
                  },
                  sameAs: ["https://github.com/zeroone-dots-ai"],
                },
                {
                  "@type": "Person",
                  "@id": "https://dotsai.in/#meet",
                  name: "Meet Deshani",
                  url: "https://dotsai.in",
                  jobTitle: "AI Engineer & Private AI Specialist",
                  worksFor: {
                    "@id": "https://dotsai.in/#organization",
                  },
                  knowsAbout: [
                    "Private AI Deployment",
                    "On-Premise LLMs",
                    "AI Agents",
                    "Machine Learning",
                    "AI Automation",
                    "Enterprise AI",
                    "GEO AI",
                  ],
                },
                {
                  "@type": "OfferCatalog",
                  name: "DotsAI Services",
                  itemListElement: [
                    {
                      "@type": "Offer",
                      itemOffered: {
                        "@type": "Service",
                        name: "Private AI Deployment",
                        url: "https://dotsai.in/private-ai/",
                      },
                    },
                    {
                      "@type": "Offer",
                      itemOffered: {
                        "@type": "Service",
                        name: "AI Automation",
                        url: "https://dotsai.in/ai-automation/",
                      },
                    },
                    {
                      "@type": "Offer",
                      itemOffered: {
                        "@type": "Service",
                        name: "AI Web Experiences",
                        url: "https://dotsai.in/web-ai-experiences/",
                      },
                    },
                    {
                      "@type": "Offer",
                      itemOffered: {
                        "@type": "Service",
                        name: "GEO AI",
                        url: "https://dotsai.in/geo-ai/",
                      },
                    },
                    {
                      "@type": "Offer",
                      itemOffered: {
                        "@type": "Service",
                        name: "Platform Engineering",
                        url: "https://dotsai.in/platform-engineering/",
                      },
                    },
                  ],
                },
                {
                  "@type": ["LocalBusiness", "ProfessionalService"],
                  "@id": "https://dotsai.in/#localbusiness",
                  name: "ZeroOne D.O.T.S AI",
                  url: "https://dotsai.in",
                  logo: "https://dotsai.in/favicon.svg",
                  image: "https://dotsai.in/og-image.png",
                  description:
                    "Best AI agency in Gurugram. Founder-led private AI deployment, AI automation, GEO, and AI web systems by Meet Deshani.",
                  telephone: "+918320065658",
                  founder: { "@id": "https://dotsai.in/#meet" },
                  address: {
                    "@type": "PostalAddress",
                    addressLocality: "Gurugram",
                    addressRegion: "Haryana",
                    addressCountry: "IN",
                    postalCode: "122001",
                  },
                  geo: {
                    "@type": "GeoCoordinates",
                    latitude: 28.4595,
                    longitude: 77.0266,
                  },
                  areaServed: [
                    { "@type": "City", name: "Gurugram" },
                    { "@type": "City", name: "New Delhi" },
                    { "@type": "Country", name: "India" },
                  ],
                  priceRange: "$$",
                  openingHoursSpecification: {
                    "@type": "OpeningHoursSpecification",
                    dayOfWeek: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
                    opens: "10:00",
                    closes: "19:00",
                  },
                  sameAs: ["https://github.com/zeroone-dots-ai"],
                },
              ],
            }),
          }}
        />
      </head>
      <body className="grain antialiased">{children}</body>
    </html>
  );
}
