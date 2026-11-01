import type { Metadata } from "next";
import Link from "next/link";

import { site } from "@/lib/site";

export const metadata: Metadata = {
	title: "Terms of use",
	description: "The ground rules for using Amrutham.",
};

// Same text as apps/mobile/lib/about/legal_text.dart. Change both together.
const updated = "1 November 2026";

export default function Terms() {
	return (
		<main className="container narrow prose">
			<p>
				<Link href="/">‹ {site.name}</Link>
			</p>
			<h1>Terms of use</h1>
			<p>These terms cover using Amrutham. By using the app you agree to them. They are short on purpose.</p>
			<p>Last updated {updated}</p>

			<h2>What Amrutham is</h2>
			<p>Amrutham is a free, open-source app (GPL-3.0) for keeping your family&apos;s health records, medicines and reminders on your phone. It is a record-keeping tool.</p>

			<h2>Not medical advice, not an emergency service</h2>
			<ul>
				<li>Amrutham does not diagnose, treat or advise. The guides are general information; talk to a qualified professional about your own situation.</li>
				<li>The app does not contact emergency services or anyone else for you. In an emergency, call your local emergency number.</li>
				<li>Reminders depend on your phone: its battery settings, silent mode, updates and notifications permission can stop them. Do not rely on Amrutham as your only way of remembering a critical dose.</li>
				<li>You are responsible for checking that what you enter is correct. Entries marked &quot;as reported&quot; are not verified.</li>
			</ul>

			<h2>Your data and your recovery code</h2>
			<p>Your data lives on your phone. We hold no copy and cannot recover it. If you lose your phone and have no backup, or lose your recovery code, your records cannot be restored by anyone. Keep a backup and keep your recovery code somewhere safe.</p>

			<h2>What you choose to show</h2>
			<p>Home screen cards, the lock-screen notice and the emergency card can be read by anyone who can see or pick up your phone. You decide what they show, and you are responsible for the choice.</p>

			<h2>Using it for others</h2>
			<p>If you keep records for someone else, such as a child or a parent, you confirm you are entitled to do so and will treat their information with care.</p>

			<h2>Licence</h2>
			<p>Amrutham is free software under the GNU General Public License v3.0. You may use, study, share and change it under that licence. The source is at github.com/JagadeeshBabuDamarasingu/amrutham. Third-party software and fonts keep their own licences, listed under Credits.</p>

			<h2>No warranty, limited liability</h2>
			<p>The app is provided &quot;as is&quot;, without warranty of any kind, as the GPL describes. To the extent the law allows, the authors are not liable for loss or harm arising from using the app, including lost data, missed reminders or mistakes in entries. Nothing here limits rights you have under law that cannot be waived.</p>

			{site.contactEmail ? (
				<p>
					Questions: <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>
				</p>
			) : null}
		</main>
	);
}
