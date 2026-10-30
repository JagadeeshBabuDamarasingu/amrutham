import Image from "next/image";
import Link from "next/link";

import { site } from "@/lib/site";

const features = [
	{
		title: "Medicine reminders",
		body: "Set doses and times once. Reminders fire on the phone itself, even offline. Only doses remind you by default.",
	},
	{
		title: "Daily metrics",
		body: "Log weight, blood pressure, sugar, steps and sleep. Values are shown exactly as logged. Never labelled normal or high.",
	},
	{
		title: "Medical history",
		body: "One timeline per person: visits, procedures, scans and medicines, with planned events kept apart from past ones.",
	},
	{
		title: "Emergency card",
		body: "Blood group, allergies, current medicines and who to call, on one page you can share or print.",
	},
	{
		title: "Records, filed as plain files",
		body: "Scan or pick prescriptions, reports and bills. They are saved as ordinary files you can open without the app.",
	},
	{
		title: "Care team and expenses",
		body: "Keep doctors and hospitals with a call button, and track medical spending by person and month.",
	},
] as const;

const openPrinciples = [
	{
		title: "Check our claims, don't trust them",
		body: "No account, no analytics, no server of ours: you can confirm each of those in the code instead of taking our word for it.",
	},
	{
		title: "No lock-in",
		body: "Records are ordinary files. Backups use standard encryption (Argon2id and AES-256-GCM), locked by a code only you hold.",
	},
	{
		title: "Mistakes get fixed in public",
		body: "Found something wrong in a health guide, or something that could be clearer? Open an issue or send a change.",
	},
] as const;

const screens = [
	{ src: "/screens/today.png", label: "Today" },
	{ src: "/screens/profile.png", label: "A family profile" },
	{ src: "/screens/metrics.png", label: "Daily metrics" },
	{ src: "/screens/history.png", label: "Medical history" },
	{ src: "/screens/emergency.png", label: "Emergency card" },
] as const;

const faqs = [
	{
		q: "Do I need an account?",
		a: "No. There is no sign-up and no login. Your records live on your phone.",
	},
	{
		q: "Does it work without internet?",
		a: "Yes. Reminders, records and history all work offline. The only time it uses the internet is when you open a link to an official website.",
	},
	{
		q: "Is it medical advice?",
		a: "No. Amrutham records what you tell it and explains how things work. It never diagnoses, scores your health, or tells you what to do.",
	},
	{
		q: "What if I lose my phone?",
		a: "You make a recovery code before your first record is saved, and you keep it somewhere that is not the phone. Restoring onto a new phone is still being built.",
	},
	{
		q: "Which languages?",
		a: "English for now. More Indian languages are planned.",
	},
] as const;

export default function Home() {
	return (
		<>
			<header className="hero">
				<nav className="container nav" aria-label="Main">
					<span className="brand">{site.name}</span>
					<div className="nav-links">
						<a href="#open-source" className="nav-link">
							Open source
						</a>
						<Link href="/privacy" className="nav-link">
							Privacy
						</Link>
					</div>
				</nav>
				<div className="container hero-grid">
					<div>
						<p className="kicker">Family health records for India</p>
						<h1>{site.tagline}</h1>
						<p className="lede">
							Medicines, records and reminders, kept on your phone. No account. No
							server of ours.
						</p>
						<div className="cta-row">
							<a className="btn btn-amber" href={site.playStoreUrl} rel="noopener">
								Get it on Google Play
							</a>
							<a className="btn btn-ghost" href="#features">
								See what it does
							</a>
						</div>
						<p className="fineprint">Android. Work in progress.</p>
					</div>
					<div className="hero-art" aria-hidden="true">
						<Image
							src="/images/dhanvantari.webp"
							alt=""
							width={540}
							height={720}
							priority
						/>
					</div>
				</div>
			</header>

			<main>
				<section className="section" id="features">
					<div className="container">
						<h2>Everything a family needs to keep track</h2>
						<p className="section-lede">
							Built around people, not around apps: add everyone once, then keep each
							person&apos;s medicines, numbers and papers together.
						</p>
						<ul className="feature-grid">
							{features.map((f) => (
								<li key={f.title} className="card">
									<h3>{f.title}</h3>
									<p>{f.body}</p>
								</li>
							))}
						</ul>
					</div>
				</section>

				<section className="section section-dark" id="privacy">
					<div className="container two-col">
						<div>
							<h2>Nothing leaves your phone unless you choose it.</h2>
							<p className="section-lede">
								Amrutham has no server to send your data to. That is the design, not a
								setting.
							</p>
						</div>
						<ul className="checks">
							<li>No account and no analytics</li>
							<li>Database encrypted with a key kept on this device</li>
							<li>Records stored as plain files you can read without the app</li>
							<li>A recovery code only you hold</li>
							<li>Health guides that name no product and track nothing you read</li>
						</ul>
					</div>
				</section>

				<section className="section" id="open-source">
					<div className="container">
						<h2>Built in the open, so you can check it.</h2>
						<p className="section-lede">
							A health app asks for a lot of trust. The source is public, so what we say
							about your privacy is something you can read for yourself.
						</p>
						<ul className="feature-grid">
							{openPrinciples.map((p) => (
								<li key={p.title} className="card">
									<h3>{p.title}</h3>
									<p>{p.body}</p>
								</li>
							))}
						</ul>
						<p className="open-cta">
							<a className="btn btn-ink" href={site.repoUrl} rel="noopener">
								View the source on GitHub
							</a>
						</p>
					</div>
				</section>

				<section className="section" id="screens">
					<div className="container">
						<h2>A look inside</h2>
						<p className="section-lede">Design previews with sample family data.</p>
						<ul className="screens">
							{screens.map((s) => (
								<li key={s.src}>
									<Image
										src={s.src}
										alt={`${s.label} screen, design preview`}
										width={390}
										height={844}
									/>
									<span>{s.label}</span>
								</li>
							))}
						</ul>
					</div>
				</section>

				<section className="section section-tint" id="faq">
					<div className="container narrow">
						<h2>Questions</h2>
						<dl className="faq">
							{faqs.map((f) => (
								<div key={f.q}>
									<dt>{f.q}</dt>
									<dd>{f.a}</dd>
								</div>
							))}
						</dl>
					</div>
				</section>

				<section className="section cta-band">
					<div className="container center">
						<h2>Start with yourself, or anyone in the family.</h2>
						<a className="btn btn-amber" href={site.playStoreUrl} rel="noopener">
							Get it on Google Play
						</a>
					</div>
				</section>
			</main>

			<footer className="footer">
				<div className="container footer-row">
					<span>
						{site.name} is a working name. Not medical advice; ask a doctor about your
						health.
					</span>
					<span className="footer-links">
						<a href={site.repoUrl} rel="noopener">
							Source
						</a>
						<Link href="/privacy">Privacy</Link>
					</span>
				</div>
			</footer>
		</>
	);
}
