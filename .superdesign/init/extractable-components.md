# Extractable Components

The starter has no reusable UI components to extract. For the Iron Sam redesign, create reusable Flutter widgets for the responsive storefront shell, product card, category chip, filter controls, cart badge, bilingual text, and checkout summary once the visual direction is approved.

## Future layout components

### StorefrontShell
- Source: new widget under `lib/widgets/storefront_shell.dart`
- Category: layout
- Description: Responsive shell with brand mark, navigation, search, language switcher, and cart access.
- Extractable props: `activeSection`, `locale`, `cartCount`
- Hardcoded: Iron Sam wordmark treatment and primary navigation labels.

### ProductCard
- Source: new widget under `lib/widgets/product_card.dart`
- Category: basic
- Description: Product image, bilingual name, price in LYD, availability, and add-to-cart affordance.
- Extractable props: `product`, `onTap`, `onAddToCart`
- Hardcoded: card structure and neutral placeholder styling.
