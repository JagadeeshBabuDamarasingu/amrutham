/// Learn content (specs F12): curated, institution-sourced, concept-level.
/// Guides explain how things work; current amounts, rules and eligibility are
/// always a link to the official site, never stated here.
///
/// `reviewedOn` / `nextReviewDue` / `verifiedOn` stay null until a person has
/// actually reviewed the guide against its source. Null is shown as "Draft",
/// so nothing here claims a review that hasn't happened.
library;

enum LearnAction { expenses, addRecord }

sealed class LearnBlock {
  const LearnBlock();
}

class LearnParagraph extends LearnBlock {
  const LearnParagraph(this.text);
  final String text;
}

class LearnHeading extends LearnBlock {
  const LearnHeading(this.text);
  final String text;
}

/// Bullets with an optional bold lead-in ("Initial: a short time…").
class LearnBullets extends LearnBlock {
  const LearnBullets(this.items);
  final List<(String? lead, String text)> items;
}

/// A labelled card of short bullet lines ("COMMONLY CHECKED").
class LearnChecklist extends LearnBlock {
  const LearnChecklist(this.label, this.items);
  final String label;
  final List<String> items;
}

/// A titled card with a line of text and a source link.
class LearnInfoCard extends LearnBlock {
  const LearnInfoCard({
    required this.title,
    required this.body,
    required this.linkLabel,
    this.url,
  });
  final String title;
  final String body;
  final String linkLabel;
  final String? url; // null = "look up yours", nothing to open
}

class LearnSourceLink extends LearnBlock {
  const LearnSourceLink({required this.label, required this.host, required this.url});
  final String label; // "CHECK THE CURRENT RULES"
  final String host; // irdai.gov.in
  final String url;
}

/// A jump to a screen inside Amrutham.
class LearnAppLink extends LearnBlock {
  const LearnAppLink({required this.title, required this.subtitle, required this.action});
  final String title;
  final String subtitle;
  final LearnAction action;
}

class LearnNote extends LearnBlock {
  const LearnNote(this.text);
  final String text;
}

class LearnGuide {
  const LearnGuide({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.blocks,
    this.reviewedOn,
    this.nextReviewDue,
    this.footer,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final List<LearnBlock> blocks;
  final DateTime? reviewedOn;
  final DateTime? nextReviewDue;
  final String? footer;

  bool get isDraft => reviewedOn == null;
  bool get reviewOverdue =>
      nextReviewDue != null && nextReviewDue!.isBefore(DateTime.now());
}

const learnGuides = <LearnGuide>[
  LearnGuide(
    id: 'waiting-period',
    category: 'Health insurance',
    title: 'What a waiting period means',
    summary: 'When a policy starts paying for certain claims, and why it varies.',
    footer:
        'Written by the Amrutham maintainers from public guidance. It describes '
        'how the category works. It is not advice, and names no insurer or product.',
    blocks: [
      LearnParagraph(
        'A waiting period is a set time after you buy a health policy during '
        'which some claims are not paid. It exists so a policy is not bought '
        'only after a need is known.',
      ),
      LearnHeading('Common kinds'),
      LearnBullets([
        ('Initial', 'a short time at the start when most claims are not paid.'),
        ('Existing conditions', 'a longer wait for things you already had.'),
        ('Specific treatments', 'a wait for named procedures.'),
      ]),
      LearnSourceLink(
        label: 'CHECK THE CURRENT RULES',
        host: 'irdai.gov.in',
        url: 'https://irdai.gov.in',
      ),
    ],
  ),
  LearnGuide(
    id: 'getting-ready-for-costs',
    category: 'Planning for health costs',
    title: 'Getting ready for medical costs',
    summary: 'Setting money aside, and keeping your papers ready.',
    footer:
        'General information about how things work. It is not financial advice, '
        'and names no product.',
    blocks: [
      LearnHeading('Cover and savings do different jobs'),
      LearnParagraph(
        'Insurance can pay for large, rare costs. Savings are for what it '
        "doesn't pay, and for waiting while a claim is processed.",
      ),
      LearnHeading('Keep your papers in one place'),
      LearnParagraph(
        'Bills, discharge summaries and policy documents are what a claim is '
        'built on. Filing them as you go is easier than finding them later.',
      ),
      LearnAppLink(
        title: "See what you've spent",
        subtitle: 'Your own entries, this year',
        action: LearnAction.expenses,
      ),
      LearnAppLink(
        title: 'File a bill or report',
        subtitle: 'Add it to Records',
        action: LearnAction.addRecord,
      ),
    ],
  ),
  LearnGuide(
    id: 'schemes-organised',
    category: 'Government schemes',
    title: 'How schemes are organised',
    summary: 'How national and state schemes are organised, and where to check them.',
    blocks: [
      LearnParagraph(
        'Most schemes fall into a few types. Which ones exist, and who can '
        'join, depends on where you live.',
      ),
      LearnInfoCard(
        title: 'National schemes',
        body:
            'Run by the central government and open across states. Often cover '
            'hospital stays for eligible households.',
        linkLabel: 'pmjay.gov.in',
        url: 'https://pmjay.gov.in',
      ),
      LearnInfoCard(
        title: 'State schemes',
        body: 'Run by your state. They can differ in who is included and what is covered.',
        linkLabel: 'Your state health department',
      ),
      LearnInfoCard(
        title: 'Through your work',
        body:
            'Some employers, and the government for its own staff, provide '
            'health cover as part of the job.',
        linkLabel: 'india.gov.in',
        url: 'https://www.india.gov.in',
      ),
      LearnNote(
        'Nothing here states an amount or a rule. Those change often. Always '
        'confirm on the official site.',
      ),
    ],
  ),
  LearnGuide(
    id: 'eligibility',
    category: 'Government schemes',
    title: 'What eligibility usually looks at',
    summary: 'The kinds of things schemes commonly check, and papers often asked for.',
    footer: "Amrutham can't tell you whether you qualify. Only the scheme can.",
    blocks: [
      LearnParagraph(
        'Each scheme sets its own rules. These are the kinds of things they '
        'commonly check.',
      ),
      LearnChecklist('COMMONLY CHECKED', [
        'Where you live',
        'Household income or category',
        'Kind of work you do',
        'Age and family size',
        'Whether you already have other cover',
      ]),
      LearnChecklist('OFTEN ASKED FOR', [
        'Proof of identity',
        'Proof of address',
        'Proof of income or category, if required',
      ]),
      LearnSourceLink(
        label: 'CHECK IF YOU QUALIFY',
        host: 'pmjay.gov.in',
        url: 'https://pmjay.gov.in',
      ),
    ],
  ),
];
