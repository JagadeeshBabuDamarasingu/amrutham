import type { Metadata, Viewport } from "next";
import { Bricolage_Grotesque, Figtree } from "next/font/google";

import { site } from "@/lib/site";

import "./globals.css";

const display = Bricolage_Grotesque({
	subsets: ["latin"],
	variable: "--font-display",
	weight: ["600", "800"],
});
const body = Figtree({ subsets: ["latin"], variable: "--font-body" });

export const metadata: Metadata = {
	metadataBase: new URL(site.url),
	title: { default: `${site.name}: ${site.tagline}`, template: `%s · ${site.name}` },
	description: site.description,
	openGraph: {
		title: `${site.name}: ${site.tagline}`,
		description: site.description,
		type: "website",
		siteName: site.name,
	},
};

export const viewport: Viewport = { themeColor: "#1f3a30" };

export default function RootLayout({ children }: { children: React.ReactNode }) {
	return (
		<html lang="en" className={`${display.variable} ${body.variable}`}>
			<body>{children}</body>
		</html>
	);
}
