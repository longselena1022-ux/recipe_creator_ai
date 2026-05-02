# Recipe Creator AI — Project Roadmap

## Immediate Fixes

These should be resolved before adding new features.

| # | Task | File | Reason |
|---|------|------|--------|
| 1 | Remove all "PantryChef" references | `lib/screens/login_screen.dart`, `lib/screens/signup_screen.dart` | Inconsistent branding |
| 2 | Fix Firestore security rules | `firestore.rules` | `savedRecipes` and `users` collections are currently unprotected |
| 3 | Clean up README | `README.md` | Contains placeholder text |

---

## Phase 1 — Onboarding Flow

**Goal:** New users get a welcoming intro before hitting an empty home screen.

- [ ] Create `lib/screens/onboarding_screen.dart` — 3-slide flow: what the app does, how ingredients work, what AI generates
- [ ] Store `hasSeenOnboarding` flag in Firestore user profile
- [ ] Update `lib/widgets/auth_gate.dart` routing: new user → onboarding → home, returning user → home directly
- [ ] Add dietary preference selection on the last onboarding slide (feeds into Phase 2)

---

## Phase 2 — User Profile Editing

**Goal:** Users can set their name, dietary restrictions, and preferences that personalize recipe generation.

- [ ] Create `lib/screens/profile_edit_screen.dart` — edit name, add dietary tags (vegetarian, vegan, gluten-free, dairy-free, nut-free)
- [ ] Update `lib/models/user_profile.dart` — add `dietaryRestrictions: List<String>` field
- [ ] Update `lib/services/user_profile_repository.dart` — save/load dietary restrictions
- [ ] Update `lib/services/recipe_generation_service.dart` — inject dietary restrictions into Gemini system prompt
- [ ] Add edit button to Profile tab in `lib/screens/home_screen.dart`

---

## Phase 3 — Recipe Filtering

**Goal:** Users can filter generated and saved recipe lists by cuisine, cook time, and dietary preference.

- [ ] Add filter chips to Recipes tab — cuisine (Italian, Asian, Mexican, American), cook time (under 30 min, under 60 min), dietary (from user profile)
- [ ] Add the same filter chips to Saved tab — filters the local list client-side
- [ ] Update Gemini prompt to optionally request specific cuisine types
- [ ] All filter logic is client-side (no new Firestore queries needed)

---

## Phase 4 — Portfolio Polish

**Goal:** Make the app look and feel complete for a portfolio.

- [ ] Better empty states — illustrated placeholders with CTAs (e.g. "Add your first ingredient →")
- [ ] Animate recipe cards appearing (subtle fade/slide-in)
- [ ] Improve match percentage logic — current word-overlap approach is rough
- [ ] Remove or make dynamic the hardcoded "Cooking with Asparagus" seasonal banner
- [ ] Update README with real screenshots, tech stack, and setup instructions

---

## Estimated Timeline

```
Immediate Fixes  →  Phase 1  →  Phase 2  →  Phase 3  →  Phase 4
    ~1 hour         ~4 hours    ~4 hours    ~4 hours    ~3 hours
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (iOS + Android) |
| Auth | Firebase Auth (email/password) |
| Database | Cloud Firestore |
| AI | Firebase AI — Gemini 2.5 Flash Lite |
| Fonts | Plus Jakarta Sans, Work Sans |
| State | StatefulWidget + StreamBuilder |
