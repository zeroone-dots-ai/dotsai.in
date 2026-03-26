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
  title: "ZeroOne D.O.T.S AI — Private AI Built for You | Meet Deshani",
  description:
    "Meet Deshani builds private AI systems for enterprises and solopreneurs. On-premise LLMs, custom agents, AI automation — deployed on YOUR server. Own your AI. Don't rent it.",
  keywords: [
    "private AI", "on-premise AI", "AI deployment", "custom AI agents",
    "enterprise AI", "AI consultant India", "ZeroOne DOTS AI", "Meet Deshani",
    "local LLM", "private LLM deployment", "AI automation", "AI solopreneur",
  ],
  authors: [{ name: "Meet Deshani", url: "https://dotsai.in" }],
  creator: "Meet Deshani",
  openGraph: {
    title: "ZeroOne D.O.T.S AI — Own Your AI. Don't Rent It.",
    description:
      "Meet Deshani builds private AI for enterprises and solopreneurs. On-premise LLMs, data sovereignty, custom agents. Your AI, your infrastructure.",
    url: "https://dotsai.in",
    siteName: "ZeroOne D.O.T.S AI",
    type: "website",
    images: [{ url: "/og-image.png", width: 1200, height: 630, alt: "ZeroOne D.O.T.S AI" }],
    locale: "en_IN",
  },
  twitter: {
    card: "summary_large_image",
    title: "ZeroOne D.O.T.S AI — Own Your AI",
    description: "Private AI built for enterprises and solopreneurs by Meet Deshani.",
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
              "@type": "Person",
              name: "Meet Deshani",
              url: "https://dotsai.in",
              jobTitle: "AI Engineer & Private AI Specialist",
              worksFor: {
                "@type": "Organization",
                name: "ZeroOne D.O.T.S AI",
                url: "https://dotsai.in",
              },
              knowsAbout: [
                "Private AI Deployment", "On-Premise LLMs", "AI Agents",
                "Machine Learning", "AI Automation", "Enterprise AI",
              ],
              contactPoint: {
                "@type": "ContactPoint",
                contactType: "Business Inquiries",
                url: "https://wa.me/918320065658",
              },
              sameAs: [
                "https://github.com/meet-deshani",
                "https://zeroonedotsai.consulting",
              ],
            }),
          }}
        />
      </head>
      <body className="grain antialiased">{children}</body>
    </html>
  );
}
