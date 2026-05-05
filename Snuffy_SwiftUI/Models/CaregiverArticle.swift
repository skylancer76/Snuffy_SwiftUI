import SwiftUI

struct CaregiverArticle: Identifiable, Hashable {
    let id: String
    let category: String
    let title: String
    let readTime: String
    let iconName: String
    let iconColor: Color
    let body: String
}

enum CaregiverArticleLibrary {
    static let caretakerArticles: [CaregiverArticle] = [
        CaregiverArticle(
            id: "ct-trust",
            category: "WELLNESS",
            title: "Building Trust With a New Pet",
            readTime: "4 min read",
            iconName: "heart.text.square.fill",
            iconColor: .orange,
            body: """
A new pet stepping into your care is in unfamiliar territory — strange smells, unfamiliar voices, and no idea who you are. Your first job isn't to entertain or train — it's to become safe.

**Start with stillness.**
Sit on the floor a few feet away and let the pet come to you. Avoid direct eye contact in the first hour; in dog body language, a hard stare reads as a challenge. Speak in low, even tones, and let the pet investigate at its own pace.

**Treats are a tool, not a bribe.**
Offer treats from a flat palm, not pinched between fingers. If the pet won't take food, that's a signal of stress — back off and give them more space. Don't push it.

**Stick to the owner's routine.**
Same food brand, same feeding times, same walk schedule. Now is not the moment to "improve" anything. Pets read consistency as safety.

**Watch the body, not the bark.**
A wagging tail isn't always friendly — a stiff, high wag with a tense body is often the opposite. Loose shoulders, a soft mouth, and a low or neutral tail are the signs you're winning trust.

**Day one looks boring on purpose.**
If your first day with a new pet is uneventful — they ate, they slept, they used the bathroom — you did it right. Excitement comes later.
"""
        ),
        CaregiverArticle(
            id: "ct-anxiety",
            category: "BEHAVIOR",
            title: "Managing Separation Anxiety",
            readTime: "5 min read",
            iconName: "waveform.path.ecg",
            iconColor: .pink,
            body: """
Separation anxiety isn't a pet "acting out" — it's a panic response. Recognising it early makes the difference between a difficult stay and an unsafe one.

**Common signs:**
- Pacing or whining within minutes of the owner leaving
- Refusing food for the first 12–24 hours
- Destructive chewing focused on doors, crates, or the owner's items
- Excessive drooling or accidents in an otherwise house-trained pet

**What helps:**
- Leave a worn item of clothing from the owner near the pet's bed.
- Use a long-lasting chew or a frozen Kong to redirect energy.
- Keep your own movements calm — a pet matches your nervous system.
- Don't make a dramatic exit or return; both spike anxiety.

**What doesn't help:**
- Punishing accidents or destruction (the pet doesn't connect cause and effect here)
- Locking them in a small room "until they calm down"
- Trying to teach new commands during the first 48 hours

**When to call the owner:**
If a pet hasn't eaten in 36 hours, is showing repeated panic signals (heavy panting at rest, dilated pupils, trembling), or has injured itself trying to escape — call. It's not a failure on your part; it's information they need.
"""
        ),
        CaregiverArticle(
            id: "ct-multipet",
            category: "SAFETY",
            title: "Hosting Multiple Pets Safely",
            readTime: "6 min read",
            iconName: "pawprint.circle.fill",
            iconColor: .purple,
            body: """
Two pets from different homes is not the same as two pets from the same home. Treat every multi-pet stay as a managed introduction, not a pre-existing friendship.

**Before they meet:**
Confirm vaccination status for every pet, including kennel cough and parvo. Ask owners about prior aggression, food guarding, and resource sensitivity. If any owner is vague or evasive, separate the pets by default.

**The first meeting:**
Walk both dogs in parallel on neutral ground for ten minutes before they ever face each other. Keep leashes loose — tight leashes communicate tension. Watch for: stiff bodies, raised hackles, prolonged staring, or one dog repeatedly circling the other.

**Feeding rules:**
Feed pets in separate rooms or crates, every meal, no exceptions. Most multi-pet conflicts start over food, even between dogs that "have never had issues." Pick up bowls when the meal ends.

**Resource zones:**
Each pet gets its own bed, its own water bowl, its own toy bin. Crowding resources is the #1 trigger for fights. If your space can't accommodate that, take fewer pets.

**Sleeping arrangements:**
Pets from different homes should sleep separately for at least the first two nights. Even if they're best friends by day, night-time territory disputes are common.

**The honest rule:**
If something feels off — a low growl during dinner, a stare that lingers — separate them and reassess. You will never regret being too cautious. You will absolutely regret the opposite.
"""
        )
    ]

    static let dogWalkerArticles: [CaregiverArticle] = [
        CaregiverArticle(
            id: "dw-leash",
            category: "SKILLS",
            title: "Leash Handling Fundamentals",
            readTime: "4 min read",
            iconName: "figure.walk",
            iconColor: .blue,
            body: """
A leash isn't a tow rope — it's a communication line. The dog reads tension changes faster than you can think them.

**Hold position.**
Loop the handle through your thumb, then close your hand around the slack. Keep your elbow soft and at your side, not extended forward. The leash should form a soft "J" shape, never a straight taut line.

**Walk with the dog, not behind it.**
Your shoulder should be roughly at the dog's shoulder. If the dog is consistently a body-length ahead, you're being walked. Slow down, change direction without warning, and reward the dog catching up.

**The two-second rule for sniff stops.**
Dogs gather most of their information through scent. Letting them sniff for 2–10 seconds at a marker (a fire hydrant, a tree base) is mental enrichment. Stopping for two minutes at every bush is not — it's a sign the walk lacks structure.

**Pulling correction without yanking.**
When the dog pulls, plant your feet and stop. Wait for the leash to slacken on its own — even a half-step back from the dog. The moment it does, you walk. Repeat as often as needed. This rewires the loop "tension = forward motion" into "slack = forward motion."

**Two hands on the leash.**
On busy streets or near other dogs, your second hand goes on the leash a foot down from the handle. This gives you mechanical control without changing your grip. It's also what saves you when something darts across the path.
"""
        ),
        CaregiverArticle(
            id: "dw-weather",
            category: "SAFETY",
            title: "Weather-Smart Walks",
            readTime: "4 min read",
            iconName: "thermometer.sun.fill",
            iconColor: .red,
            body: """
Dogs don't sweat the way humans do. Their thermoregulation has a much narrower window, and they will keep walking past their limit because that's what you asked of them.

**The pavement test.**
Press the back of your hand to the asphalt for seven seconds. If you can't hold it there, the dog can't walk on it. Paw pads burn fast and silently — most owners never see the early damage.

**Heat thresholds:**
- Above 30°C / 86°F: short walks, shaded routes, water every 10 minutes
- Above 35°C / 95°F: skip the walk, do indoor enrichment instead
- Brachycephalic breeds (pugs, bulldogs, frenchies): drop those numbers by 5°C

**Heatstroke warning signs:**
Heavy panting that doesn't slow down, brick-red gums, stumbling, glassy eyes, vomiting. Stop immediately, move to shade, wet the paws and belly with cool (not cold) water. Call the owner. If symptoms persist for five minutes, this is a vet emergency, not a wait-it-out situation.

**Cold weather:**
Below 0°C / 32°F: short-coated dogs need a jacket. Below -7°C / 20°F: every dog should be in and out quickly. Rinse paws after walks — road salt and de-icer cause chemical burns and toxicity if licked.

**Rain is mostly fine.**
Dogs handle rain better than we do. The exception is thunderstorms — many dogs panic at the first crack of thunder. If you're caught out, find shelter and wait it out rather than rushing home through chaos.
"""
        ),
        CaregiverArticle(
            id: "dw-bodylang",
            category: "BEHAVIOR",
            title: "Reading Canine Body Language",
            readTime: "5 min read",
            iconName: "eye.fill",
            iconColor: .green,
            body: """
By the time a dog growls or snaps, it has already given you four or five quieter signals. Reading those signals is what separates a careful walker from a lucky one.

**The escalation ladder (calm → stressed):**
1. Lip lick or nose lick (when no food is around)
2. Yawn (when not tired)
3. Looking away / turning the head
4. Whale eye — whites of the eyes showing as the head stays fixed
5. Stiff body, closed mouth, weight forward
6. Low growl
7. Air snap or bite

If you see signals 1–4, give the dog more space. Don't push past them to "see if it's fine."

**Tail reading:**
- High and stiff with small fast wags = arousal, often unfriendly
- Loose, sweeping wags at mid-height = friendly
- Tucked tail = fear; do not approach or hover
- Wagging only the tip = curious but not committed

**Greeting another dog:**
A healthy greeting is brief — a few seconds of side-by-side sniffing, then both dogs disengage on their own. If they freeze, mount, or one dog tries to put a paw or chin over the other's shoulder, separate calmly. That's not play, that's a status conversation.

**The 3-second rule.**
At a new greeting, count "one-thousand-one, one-thousand-two, one-thousand-three" and walk away. If both dogs want more, they'll tell you by re-engaging. If one wants out, you've already saved the situation.

**Trust your gut, then your eyes.**
If something feels wrong — even before you can name what — create distance first, analyse later. You'll be right more often than you're wrong, and the cost of being wrong about a real threat is much higher than the cost of an unnecessary detour.
"""
        )
    ]
}
