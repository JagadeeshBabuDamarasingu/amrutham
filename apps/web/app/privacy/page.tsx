import type { Metadata } from "next";
import Link from "next/link";

import { site } from "@/lib/site";

export const metadata: Metadata = {
	title: "Privacy",
	description: `How ${site.name} handles your data: it stays on your phone.`,
};

export default function Privacy() {
	return (
		<main className="container narrow prose">
			<p>
				<Link href="/">‹ {site.name}</Link>
			</p>
			<h1>Privacy</h1>
			<p>
				{site.name} keeps your family&apos;s health information on your phone. This page
				says plainly what that means.
			</p>

			<h2>What we collect</h2>
			<p>
				Nothing. {site.name} has no account, no analytics, no advertising and no server
				that receives your data. We cannot see your records, and we cannot recover them
				for you.
			</p>

			<h2>Where your information lives</h2>
			<ul>
				<li>
					Names, medicines, measurements, history, expenses and care-team details are
					stored in a database on your phone, encrypted with a key kept in the
					phone&apos;s secure storage.
				</li>
				<li>
					Documents you add are saved as ordinary files in a folder on your phone.
				</li>
				<li>
					If you turn on home screen emergency cards, the app keeps a small copy of only
					the details you chose to show (for example a name, blood group, allergies and a
					phone number to dial) in a file on your phone, so the home screen can display
					it. That copy is not encrypted like the database. Anyone who can see your home
					screen can read what a card shows. The copy is left out of Android&apos;s cloud
					backup and device transfer, and it is deleted when you turn the cards off. The
					cards are off until you turn them on.
				</li>
				<li>
					Your recovery code is never stored. The phone keeps only a salted hash used to
					check a code you type.
				</li>
			</ul>

			<h2>What the app can ask your phone for</h2>
			<ul>
				<li>
					<strong>Notifications and alarms</strong>, to remind you of medicine doses.
				</li>
				<li>
					<strong>Camera, photos and files</strong>, only when you choose to add a
					record.
				</li>
				<li>
					<strong>The phone dialer</strong>, only when you tap a call button. The call
					is made by your phone, not by the app.
				</li>
				<li>
					<strong>The share sheet</strong>, only when you choose to share or export
					something. What you share is sent by the app you pick, not by {site.name}.
				</li>
			</ul>

			<h2>The internet</h2>
			<p>
				The app does not send your information anywhere. It opens your browser only when
				you tap a link to an official website, such as a government health site.
			</p>

			<h2>Health guides</h2>
			<p>
				The guides in the app are general information, not medical advice. Reading them
				leaves no history, and nothing you read is recorded or shared.
			</p>

			<h2>Children</h2>
			<p>
				A parent or guardian can add a child as a profile. The information stays on the
				parent&apos;s phone like everything else.
			</p>

			<h2>Changes</h2>
			<p>
				If this changes, the new version will be published here with its date before an
				app update relies on it.
			</p>

			{site.contactEmail ? (
				<p>
					Questions: <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>
				</p>
			) : null}
		</main>
	);
}
