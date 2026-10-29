export const site = {
	name: "Amrutham",
	tagline: "Your family's health, in files you own.",
	description:
		"Amrutham keeps your family's medicines, records and reminders on your phone. No account. No server of ours.",
	url:
		process.env.NEXT_PUBLIC_SITE_URL ??
		(process.env.NODE_ENV === "production" ? "https://amrutham.app" : "http://localhost:3000"),
	// See .env.example: the id is still Flutter's default until the app is renamed.
	playStoreUrl:
		process.env.NEXT_PUBLIC_PLAY_STORE_URL ??
		"https://play.google.com/store/apps/details?id=app.amrutham",
	contactEmail: process.env.NEXT_PUBLIC_CONTACT_EMAIL || null,
} as const;
