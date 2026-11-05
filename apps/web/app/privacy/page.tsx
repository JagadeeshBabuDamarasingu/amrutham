import type { Metadata } from "next";
import Link from "next/link";

import { site } from "@/lib/site";

export const metadata: Metadata = {
	title: "Privacy policy",
	description: "How Amrutham handles your data: it stays on your phone.",
};

// Same text as apps/mobile/lib/about/legal_text.dart. Change both together.
const updated = "5 November 2026";

export default function Privacy() {
	return (
		<main className="container narrow prose">
			<p>
				<Link href="/">‹ {site.name}</Link>
			</p>
			<h1>Privacy policy</h1>
			<p>Amrutham keeps your family&apos;s health information on your phone. This page says plainly what that means.</p>
			<p>Last updated {updated}</p>

			<h2>What we collect</h2>
			<p>Nothing. Amrutham has no account, no analytics, no advertising and no server of ours that receives your data. We cannot see your records, and we cannot recover them for you.</p>

			<h2>Where your information lives</h2>
			<ul>
				<li>Names, medicines, measurements, history, expenses and care-team details are stored in a database on your phone, encrypted with a key kept in the phone&apos;s secure storage.</li>
				<li>Documents you add are saved as ordinary files in a folder on your phone.</li>
				<li>Your recovery code is never stored. The phone keeps only a salted hash used to check a code you type.</li>
				<li>If you turn on a phone lock, Amrutham asks your phone to check your fingerprint, face or screen lock. It never sees or stores them.</li>
			</ul>

			<h2>Home screen cards and the lock-screen notice</h2>
			<p>Both are off until you turn them on. When on, the app keeps a small copy of only the details you chose to show (for example a name, blood group, allergies and phone numbers to dial) in a file on your phone, so the home screen or notification can display it.</p>
			<p>That copy is not encrypted like the database. Anyone who can see your home screen or lock screen can read what is shown. The copy is left out of Android&apos;s cloud backup and device transfer, and it is deleted when you turn the feature off.</p>

			<h2>Medicine alarms and photos</h2>
			<p>Alarms are set on your phone by the phone&apos;s own alarm system. They work with no internet. When one rings it can open a full-screen alarm over the lock screen, so an elder can answer it without unlocking the phone. That screen shows only the medicine name, dose and the photo you chose.</p>
			<p>A photo of a medicine (so that someone can recognise the tablet) is saved on your phone with your other records, and is included in your encrypted backup. It is never uploaded anywhere by the app.</p>

			<h2>Backups</h2>
			<p>A backup is a single file, encrypted with a key made from your recovery code before it leaves the database. You choose where it goes:</p>
			<ul>
				<li>A folder on your phone or a storage service you pick.</li>
				<li>Your own Google Drive, in the app&apos;s private area (the &quot;app data&quot; space). Amrutham can only see files it created there, and nothing else in your Drive. Signing in uses Google&apos;s own sign-in; Amrutham does not receive your password.</li>
				<li>Google can see that an encrypted file exists and its size, as with any file you store with them. They cannot read its contents without your recovery code. Google&apos;s own terms and privacy policy apply to what you store with them.</li>
			</ul>

			<h2>What the app can ask your phone for</h2>
			<ul>
				<li>Notifications, exact alarms and full-screen alerts, to ring medicine reminders on time and show them over the lock screen. Reminders work without the internet.</li>
				<li>Camera, photos and files, only when you choose to add a record or a medicine photo.</li>
				<li>The phone dialer, only when you tap a call button. The call is made by your phone, not by the app.</li>
				<li>The share sheet, only when you choose to share or export something. What you share is sent by the app you pick, not by Amrutham.</li>
				<li>Fingerprint, face or screen lock, only to unlock the app if you turn the app lock on. With the app lock on, Amrutham also hides its preview in the recent-apps list. Alarms are never blocked by the lock.</li>
			</ul>

			<h2>The internet</h2>
			<p>The app does not send your information anywhere on its own. It uses the internet only when you back up to Google Drive, or open a link to an official website such as a government health site.</p>

			<h2>Health guides</h2>
			<p>The guides in the app are general information, not medical advice. Reading them leaves no history, and nothing you read is recorded or shared.</p>

			<h2>Children</h2>
			<p>A parent or guardian can add a child as a profile. The information stays on the parent&apos;s phone like everything else.</p>

			<h2>Your choices</h2>
			<p>Everything is yours to export or delete. Removing the app removes the database and documents from the phone; backups you made stay where you put them until you delete them.</p>

			{site.contactEmail ? (
				<p>
					Questions: <a href={`mailto:${site.contactEmail}`}>{site.contactEmail}</a>
				</p>
			) : null}
		</main>
	);
}
