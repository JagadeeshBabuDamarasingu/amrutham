/// Learn content (specs F12): curated, institution-sourced, concept-level.
/// Guides explain how things work; current amounts, rules and eligibility are
/// always a link to the official site, never stated here.
///
/// `reviewedOn` / `nextReviewDue` / `verifiedOn` stay null until a person has
/// actually reviewed the guide against its source. Null is shown as "Draft",
/// so nothing here claims a review that hasn't happened.
library;

enum LearnAction { expenses, addRecord }

/// A topic area on the Learn tab. `isPrivate` hubs show the "Private here"
/// banner: reading is never recorded anywhere (Amrutham keeps no history), and
/// nothing from these topics is notified or shown across profiles.
enum LearnHub {
  money('Insurance and money', 'How cover, savings and government schemes fit together.', false),
  sexualHealth('Sexual health', 'Plain, factual guides from public health sources.', true),
  growingUp('Growing up and family', "Puberty, periods, pregnancy and a baby's first care.", true),
  mentalWellbeing('Mental wellbeing', 'Plain guides on feelings, stress and getting help.', true);

  const LearnHub(this.title, this.blurb, this.isPrivate);
  final String title;
  final String blurb;
  final bool isPrivate;
}

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

enum CalloutTone { know, good }

/// A bold, short statement. `know` is amber, `good` is the dark green card.
class LearnCallout extends LearnBlock {
  const LearnCallout({required this.tone, required this.title, this.body});
  final CalloutTone tone;
  final String title;
  final String? body;
}

class LearnMythFact extends LearnBlock {
  const LearnMythFact({required this.myth, required this.fact});
  final String myth;
  final String fact;
}

/// A white card with a title and bullets ("What it can feel like").
class LearnList extends LearnBlock {
  const LearnList(this.title, this.items);
  final String title;
  final List<String> items;
}

/// Switchable views of one guide ("In yourself" / "In someone I care about").
class LearnTabs extends LearnBlock {
  const LearnTabs(this.tabs);
  final List<(String label, List<LearnBlock> blocks)> tabs;
}

/// Amber button to the Get help now page.
class LearnHelpLink extends LearnBlock {
  const LearnHelpLink();
}

class LearnNote extends LearnBlock {
  const LearnNote(this.text);
  final String text;
}

class LearnGuide {
  const LearnGuide({
    required this.id,
    this.hub = LearnHub.money,
    required this.category,
    required this.title,
    required this.summary,
    required this.blocks,
    this.reviewedOn,
    this.nextReviewDue,
    this.footer,
  });

  final String id;
  final LearnHub hub;
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

// ---------------------------------------------------------------------------
// Clinical topics. Concept-level and conservative: what a thing is, what is
// generally true, when to ask for help. No doses, no schedules, no amounts —
// those change and live at the official source each guide links to.
// ---------------------------------------------------------------------------

const _draftFooter =
    'Written by the Amrutham maintainers from public guidance. General '
    'information, not medical advice. If you are worried about your health or '
    "someone else's, ask a doctor or health worker.";

const _who = LearnSourceLink(
  label: 'READ THE SOURCE',
  host: 'who.int',
  url: 'https://www.who.int',
);
const _mohfw = LearnSourceLink(
  label: 'CHECK THE CURRENT GUIDANCE',
  host: 'mohfw.gov.in',
  url: 'https://mohfw.gov.in',
);
const _naco = LearnSourceLink(
  label: 'CHECK THE CURRENT GUIDANCE',
  host: 'naco.gov.in',
  url: 'https://naco.gov.in',
);

const clinicalGuides = <LearnGuide>[
  // ---- Sexual health ------------------------------------------------------
  LearnGuide(
    id: 'key-facts',
    hub: LearnHub.sexualHealth,
    category: 'Key facts',
    title: 'Key facts',
    summary: 'Five things worth remembering.',
    footer: _draftFooter,
    blocks: [
      LearnCallout(
        tone: CalloutTone.know,
        title: "A condom lowers the risk a lot. It doesn't remove it.",
        body: "Some infections, like HPV and herpes, spread through skin a condom doesn't cover.",
      ),
      LearnCallout(
        tone: CalloutTone.know,
        title: "No symptoms doesn't mean no infection.",
        body: 'Many infections show no signs. A test is the only way to know.',
      ),
      LearnCallout(
        tone: CalloutTone.good,
        title: "When HIV treatment is working, the virus isn't passed on through sex.",
        body: 'Treatment also lets people live long, healthy lives.',
      ),
      LearnMythFact(
        myth: 'You can catch HIV from a hug or a shared glass.',
        fact: "HIV doesn't spread through touch, food, toilets or mosquitoes.",
      ),
      LearnCallout(
        tone: CalloutTone.good,
        title: 'Most HPV infections clear on their own.',
        body: 'A vaccine and regular screening help protect against the serious effects.',
      ),
      _who,
    ],
  ),
  LearnGuide(
    id: 'sexual-wellness',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'Sexual wellness',
    summary: 'Consent, talking, protection, and looking after yourself.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Sexual wellness is about feeling safe, respected and informed. It '
        'covers more than avoiding illness.',
      ),
      LearnHeading('Consent'),
      LearnParagraph(
        'Consent is a clear, freely given yes. It can be taken back at any '
        'time, and silence or going along is not a yes. Nobody should be '
        'pressured, and anyone can say stop.',
      ),
      LearnHeading('Talking about it'),
      LearnParagraph(
        'It helps to talk with a partner about protection, testing and what '
        "each of you is comfortable with, before it's urgent.",
      ),
      LearnHeading('Protection'),
      LearnBullets([
        ('Condoms', 'lower the risk of many infections and of pregnancy. They do not remove it.'),
        ('Other contraception', 'can prevent pregnancy but does not protect against infections.'),
        ('Vaccines', 'exist for some infections, such as hepatitis B and HPV. Ask a doctor about them.'),
      ]),
      LearnHeading('Looking after yourself'),
      LearnParagraph(
        'Get tested when you start a new relationship, or if you have had a '
        'risk. See a health worker for sores, pain, or unusual discharge. '
        'Avoid treating yourself without advice.',
      ),
      _who,
    ],
  ),
  LearnGuide(
    id: 'how-infections-spread',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'How infections spread',
    summary: "Which contact passes HIV and other infections, and which doesn't.",
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Infections spread in specific ways. Knowing which contact carries '
        'risk, and which does not, removes both false worry and false comfort.',
      ),
      LearnList('HIV can spread through', [
        'Sex without protection',
        'Sharing needles or syringes',
        'Blood that has not been screened',
        'A mother to her baby, in pregnancy, birth or breastfeeding, unless prevented with treatment',
      ]),
      LearnList("HIV doesn't spread through", [
        'Touch, hugging or shaking hands',
        'Sharing food, plates or cups',
        'Toilets or swimming',
        'Mosquito bites, coughs or sneezes',
      ]),
      LearnParagraph(
        'Other infections, such as HPV and herpes, can spread through '
        'skin-to-skin contact in the genital area. A condom lowers that risk '
        'but does not cover all the skin.',
      ),
      _naco,
    ],
  ),
  LearnGuide(
    id: 'hiv-and-aids',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'HIV and AIDS',
    summary: 'The difference, how treatment works, and testing.',
    footer: _draftFooter,
    blocks: [
      LearnHeading('The difference'),
      LearnParagraph(
        'HIV is a virus that weakens the body\'s defences. AIDS is the late '
        'stage, when HIV that has not been treated has badly damaged them.',
      ),
      LearnHeading('Treatment'),
      LearnParagraph(
        'Daily treatment keeps the virus under control. Most people who start '
        'treatment and keep taking it stay healthy and do not develop AIDS. '
        'When treatment is working, the virus is not passed on through sex.',
      ),
      LearnHeading('Testing'),
      LearnParagraph(
        'A test is the only way to know. Right after a risk a test may not yet '
        'show it, so ask the testing centre when to test again. Government '
        'health facilities offer free, confidential testing and treatment.',
      ),
      _naco,
    ],
  ),
  LearnGuide(
    id: 'hpv',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'HPV',
    summary: 'A common virus, the vaccine, and screening.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'HPV is a very common virus that spreads through skin-to-skin '
        'intimate contact. Most people who get it never know, and most '
        'infections clear on their own.',
      ),
      LearnParagraph(
        'Some types can, over many years, cause changes that lead to cancer, '
        'most often of the cervix. That is why prevention matters.',
      ),
      LearnList('What helps', [
        'A vaccine that protects against the main high-risk types',
        'Regular cervical screening, which finds changes early',
        'Condoms, which lower the risk but do not remove it',
      ]),
      LearnParagraph(
        'Ask a doctor or health worker about the vaccine, who it is '
        'recommended for, and when screening is due.',
      ),
      _who,
    ],
  ),
  LearnGuide(
    id: 'testing-and-help',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'Testing and getting help',
    summary: 'What to expect, and where to go.',
    footer: _draftFooter,
    blocks: [
      LearnHeading('What to expect'),
      LearnParagraph(
        'You will usually be asked a few private questions, offered a simple '
        'test (a blood sample, or a swab or urine sample depending on the '
        'infection), and given the result with advice. What you say and the '
        'result are confidential.',
      ),
      LearnHeading('Where to go'),
      LearnParagraph(
        'A government health facility or district hospital, or a clinic you '
        'trust. You do not need to bring anyone.',
      ),
      LearnList('See a health worker soon if you have', [
        'Sores, lumps or blisters in the genital area',
        'Unusual discharge, or pain when passing urine or during sex',
        'A partner who has told you they have an infection',
        'Had sex without protection and are worried',
      ]),
      _naco,
    ],
  ),
  LearnGuide(
    id: 'privacy-sensitive',
    hub: LearnHub.sexualHealth,
    category: 'Sexual health',
    title: 'Privacy for sensitive topics',
    summary: 'What Amrutham does and does not keep about what you read.',
    footer: 'This describes how Amrutham itself works.',
    blocks: [
      LearnParagraph(
        'Reading these guides leaves no trace in Amrutham. It keeps no '
        'reading history, sends no notifications about these topics, and '
        'never shows them on anyone else\'s profile.',
      ),
      LearnList('What stays on this phone', [
        'Nothing you read here is saved',
        'Nothing is sent to us or to anyone',
        'The tip on the Today tab is the same for everyone',
      ]),
      LearnNote(
        'If someone else uses your phone, your screen lock is what keeps '
        'what you do in any app private.',
      ),
    ],
  ),

  // ---- Growing up and family ----------------------------------------------
  LearnGuide(
    id: 'puberty',
    hub: LearnHub.growingUp,
    category: 'Growing up',
    title: 'Puberty',
    summary: 'What changes for boys and girls, and how to look after yourself.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Puberty is the time when a child\'s body grows into an adult\'s. It '
        'usually starts somewhere in the pre-teen to early-teen years, and the '
        'timing varies a lot from child to child. Being earlier or later than '
        'friends is usually normal.',
      ),
      LearnList('Changes many children notice', [
        'Growing taller, faster than before',
        'Body hair, and more sweat and body odour',
        'Skin that gets oily, and pimples',
        'Voice changes and growth of the chest, hips or shoulders',
        'Mood swings, and new feelings',
      ]),
      LearnHeading('Looking after yourself'),
      LearnParagraph(
        'Wash daily, wear clean clothes, eat regular meals and sleep well. '
        'Talk to a parent, relative, teacher or health worker you trust when '
        'something worries you. Nobody should have to guess.',
      ),
      LearnParagraph(
        'Ask a doctor if changes start very early, have not started by the '
        'late teens, or if something feels painful or wrong.',
      ),
      _who,
    ],
  ),
  LearnGuide(
    id: 'periods',
    hub: LearnHub.growingUp,
    category: 'Growing up',
    title: 'Periods and menstrual health',
    summary: 'After the first period: managing, hygiene, and when to ask a doctor.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'A period is monthly bleeding from the womb. It is a normal part of '
        'growing up and not something to hide or be ashamed of. In the first '
        'year or two, periods are often irregular.',
      ),
      LearnHeading('Managing it'),
      LearnBullets([
        ('Change', 'a pad or cloth regularly, and more often when the bleeding is heavy.'),
        ('Wash', 'your hands before and after, and wash and fully dry any reusable cloth in the sun.'),
        ('Pain', 'is common. Rest, warmth and a gentle walk can help.'),
        ('Keep going', 'to school and normal activities. A period is not an illness.'),
      ]),
      LearnList('Ask a doctor if', [
        'The bleeding is so heavy you soak through often',
        'The pain stops you doing your usual activities',
        'Periods stop for a long time after they have been regular',
        'You bleed between periods, or have a bad smell or itching',
      ]),
      _mohfw,
    ],
  ),
  LearnGuide(
    id: 'pregnancy',
    hub: LearnHub.growingUp,
    category: 'Pregnancy',
    title: 'Pregnancy',
    summary: 'Check-ups, eating and resting well, and warning signs.',
    footer: _draftFooter,
    blocks: [
      LearnCallout(
        tone: CalloutTone.know,
        title: 'Get help straight away for heavy bleeding, a severe headache, or much less baby movement.',
      ),
      LearnHeading('Check-ups'),
      LearnParagraph(
        'Start antenatal check-ups early and keep going to them. They find '
        'problems while they are easy to deal with. Government health '
        'facilities offer check-ups and the supplements your health worker '
        'advises, such as iron and folic acid.',
      ),
      LearnHeading('Looking after yourself'),
      LearnParagraph(
        'Eat a varied diet, rest, and stay active in the way your health '
        'worker suggests. Avoid tobacco and alcohol, and check with a '
        'health worker before taking any medicine.',
      ),
      LearnList('Go to a health facility straight away for', [
        'Heavy bleeding',
        'A severe headache, blurred vision, or swelling of the face and hands',
        'Fever, or severe pain in the belly',
        'Fluid leaking from the vagina',
        'The baby moving much less than usual',
        'Fits, or fainting',
      ]),
      _who,
    ],
  ),
  LearnGuide(
    id: 'after-the-birth',
    hub: LearnHub.growingUp,
    category: 'Pregnancy',
    title: 'After the birth',
    summary: 'Looking after the mother and the newborn.',
    footer: _draftFooter,
    blocks: [
      LearnHeading('The mother'),
      LearnParagraph(
        'Rest, eat well, and go to your post-birth check-ups. Some bleeding '
        'is normal and should slowly lessen.',
      ),
      LearnList('Get help straight away for the mother if', [
        'Bleeding is heavy or soaks pads quickly',
        'There is fever, or a foul-smelling discharge',
        'There is severe belly pain, or a severe headache',
        'She feels very low, or has thoughts of harming herself or the baby',
      ]),
      LearnHeading('The newborn'),
      LearnParagraph(
        'Keep the baby warm and close, ideally skin to skin. WHO recommends '
        'breastfeeding exclusively for the first six months. Keep the cord '
        'stump clean and dry, and wash your hands before handling the baby.',
      ),
      LearnList('Take a newborn to a health facility straight away if', [
        'Not feeding, or very sleepy and hard to wake',
        'Fast or difficult breathing',
        'Fever, or the baby feels very cold',
        'Yellow skin or eyes, especially early or spreading',
        'Fits, or the cord area is red or has pus',
      ]),
      _who,
    ],
  ),
  LearnGuide(
    id: 'baby-vaccines',
    hub: LearnHub.growingUp,
    category: 'Your baby',
    title: 'Vaccines for your baby',
    summary: 'Why on time matters, and a record you keep yourself.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        "Vaccines protect a baby from serious diseases at the age when they're "
        'most at risk. Giving them on time gives the protection when it is needed.',
      ),
      LearnHeading('Where and what it costs'),
      LearnParagraph(
        'The national immunisation programme gives routine childhood vaccines '
        'through government health facilities and anganwadi sessions.',
      ),
      LearnHeading('Keep the card'),
      LearnParagraph(
        'Keep the vaccination or mother-and-child card safe, and bring it to '
        'every visit. If a dose is missed, ask the health worker. Usually you '
        'continue where you left off rather than starting again.',
      ),
      LearnNote(
        'Amrutham does not list the vaccine schedule. It changes, so check '
        'it at the official source or with your health worker.',
      ),
      _mohfw,
    ],
  ),

  // ---- Mental wellbeing ---------------------------------------------------
  LearnGuide(
    id: 'stress-anxiety',
    hub: LearnHub.mentalWellbeing,
    category: 'Feelings',
    title: 'Stress and anxiety',
    summary: 'What is normal, and simple ways to settle.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Feeling stressed or anxious from time to time is a normal response to '
        'pressure. It becomes a problem when it lasts, or starts to get in the '
        'way of daily life.',
      ),
      LearnList('Things that often help', [
        'Slow breathing: in through the nose, out slowly, for a few minutes',
        'A regular routine, meals and sleep',
        'Moving your body, even a short walk',
        'Talking to someone you trust',
        'Cutting down on alcohol, tobacco and too much caffeine',
      ]),
      LearnList('Ask for help if', [
        'The worry or fear lasts for weeks',
        'It stops you working, studying, sleeping or seeing people',
        'You have sudden attacks of fear, with a racing heart or breathlessness',
        'You are using alcohol or other substances to cope',
      ]),
      LearnHelpLink(),
      _who,
    ],
  ),
  LearnGuide(
    id: 'low-mood',
    hub: LearnHub.mentalWellbeing,
    category: 'Feelings',
    title: 'Low mood and depression',
    summary: 'Signs, what helps, and when to ask for help.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Everyone feels low sometimes. Depression is when low mood, or losing '
        'interest in things, lasts for weeks and affects how you live. It is a '
        'health condition, not a weakness or a failing.',
      ),
      LearnList('Signs', [
        'Feeling sad, empty or hopeless most of the day',
        'Losing interest in things you used to enjoy',
        'Changes in sleep or appetite, or feeling tired all the time',
        'Trouble concentrating, or feeling worthless or guilty',
      ]),
      LearnParagraph(
        'Depression is common and it responds to help: talking to someone, '
        'a routine, and where needed treatment from a doctor or counsellor. '
        'Ask for help early. It does not have to get worse first.',
      ),
      LearnHelpLink(),
      _who,
    ],
  ),
  LearnGuide(
    id: 'helping-someone',
    hub: LearnHub.mentalWellbeing,
    category: 'Feelings',
    title: 'Helping someone else',
    summary: 'What to say, what to avoid, and when to get help.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'You do not need the right words. Showing up and listening matters '
        'more than fixing anything.',
      ),
      LearnList('What helps', [
        'Ask how they really are, and listen without hurrying',
        'Say you are there, and that what they feel is real',
        'Offer practical help, like going with them to see a doctor',
        'Check in again later',
      ]),
      LearnList('What to avoid', [
        '"Snap out of it", or telling them others have it worse',
        'Arguing about whether they should feel this way',
        'Promising to keep a secret if their life may be at risk',
      ]),
      LearnParagraph(
        'If they talk about wanting to die or to harm themselves, take it '
        'seriously and get help now.',
      ),
      LearnHelpLink(),
      _who,
    ],
  ),
  LearnGuide(
    id: 'after-a-baby',
    hub: LearnHub.mentalWellbeing,
    category: 'Feelings',
    title: 'After a baby arrives',
    summary: 'Feeling low as a new parent is common.',
    footer: _draftFooter,
    blocks: [
      LearnParagraph(
        'Many new mothers feel tearful or overwhelmed in the first days. This '
        'is common and usually passes. Fathers and partners can feel low too.',
      ),
      LearnList('Ask a doctor or health worker if', [
        'The low feeling lasts more than a couple of weeks, or gets worse',
        'You cannot sleep even when the baby sleeps, or cannot eat',
        'You feel you cannot care for the baby, or have no feelings for them',
        'You have frightening thoughts, or thoughts of harming yourself or the baby',
      ]),
      LearnParagraph(
        'It is a health condition that can be treated, and asking for help is '
        'part of caring for the baby.',
      ),
      LearnHelpLink(),
      _who,
    ],
  ),
  LearnGuide(
    id: 'thoughts-of-ending-life',
    hub: LearnHub.mentalWellbeing,
    category: 'Help now',
    title: 'Thoughts of ending your life',
    summary: 'Signs in yourself or someone you care about, and how to ask.',
    footer: _draftFooter,
    blocks: [
      LearnTabs([
        (
          'In yourself',
          [
            LearnCallout(
              tone: CalloutTone.good,
              title: "These thoughts can pass, and help works. They don't make you weak.",
            ),
            LearnList('What it can feel like', [
              "Feeling that life isn't worth living, or that others would be better off without you",
              "Feeling trapped, or in pain that won't end",
              'Pulling away from people, or drinking more',
            ]),
            LearnList('What to do now', [
              'Tell one person you trust how you feel, today',
              'Keep away from anything you could use to hurt yourself',
              "Take it one hour at a time. You don't have to solve everything",
            ]),
          ],
        ),
        (
          'In someone I care about',
          [
            LearnCallout(
              tone: CalloutTone.good,
              title: 'Asking directly does not put the idea in their head. It often brings relief.',
            ),
            LearnList('Signs to take seriously', [
              'Talking about wanting to die, or being a burden',
              'Giving things away, or saying goodbye',
              'Pulling away, or using more alcohol or drugs',
              'A sudden calm after a long period of distress',
            ]),
            LearnList('What to do', [
              'Ask plainly: "Are you thinking of ending your life?"',
              'Listen without arguing, and stay with them',
              'Help keep away anything they could use to hurt themselves',
              "Don't promise secrecy. Get help now",
            ]),
          ],
        ),
      ]),
      LearnHelpLink(),
    ],
  ),
];

/// Everything on the Learn tab.
const allGuides = <LearnGuide>[...learnGuides, ...clinicalGuides];
