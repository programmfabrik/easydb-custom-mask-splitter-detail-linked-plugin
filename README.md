# Custom Mask Splitter: Show References

A custom mask splitter plugin for easydb/Fylr that displays reverse references - showing all objects that link to the currently viewed object in the detail view.

## Overview

When viewing an object in detail mode, this plugin automatically searches for and displays all other objects in the database that reference it through linked fields. Results are grouped by object type and can optionally be further categorized by the specific field containing the reference.

### Key Features

- **Reverse Reference Display**: Automatically finds and displays all objects that reference the current object
- **Multiple Display Modes**: Choose between Standard, Short, or Text display formats
- **Object Type Filtering**: Select which object types to search for references
- **Field-Level Grouping** (Fylr only): Optionally group references by the specific field that contains the link
- **Inheritance Control** (Fylr only): Option to include or exclude inherited field values
- **Pagination**: Built-in pagination for large result sets (10 items per page)
- **Nested Field Support** (Fylr only): Searches through nested table structures

## Compatibility

| Platform | Version | Status | Notes |
|----------|---------|--------|-------|
| **Fylr** | All versions | ✅ Full support | All features available |
| **easydb 5** | 5.x | ✅ Supported | Inheritance and Show Fields options not available |

## Installation

### From Source

1. Clone or pull the repository into your plugins directory:
   ```sh
   git clone https://github.com/programmfabrik/easydb-custom-mask-splitter-detail-linked-plugin.git
   ```

2. Build the plugin:
   ```sh
   cd easydb-custom-mask-splitter-detail-linked-plugin
   make all
   ```

3. Restart your easydb/Fylr instance

4. **For Fylr**: Navigate to the Plugin Manager and activate the plugin

## Configuration

### Adding the Mask Splitter

1. Open the **Mask Editor** in the administration area
2. Select the mask where you want to display reverse references
3. Click the **"+"** button to add a new element
4. Select **"Display of references"** from the mask splitter options
5. Position the splitter where you want the references to appear in the detail view

### Configuration Options

| Option | Description | Available |
|--------|-------------|-----------|
| **Mode** | Display format for referenced objects | All platforms |
| **Object Types** | Select which object types to search for references | All platforms |
| **Include Inherited Data** | Include references from inherited field values | Fylr only |
| **Show Fields** | Group references by the specific field containing the link | Fylr only |

### Display Modes

- **Standard**: Full card display with thumbnail and detailed information
- **Short**: Compact single-line display, similar to nested object condensed view
- **Text**: Text-only display showing the object's standard text representation

### Show Fields Option (Fylr only)

When enabled, references are grouped not only by object type but also by the specific field that contains the reference. This is useful when:

- An object type has multiple linked fields pointing to the same target type
- You need to understand the context of each reference
- The same object appears in different fields of the referencing object

**Example**: If "Document" has two fields linking to "Person" (Author and Reviewer), enabling "Show Fields" will display:
- Document (Author): List of documents where this person is the author
- Document (Reviewer): List of documents where this person is a reviewer

## Technical Details

### How It Works

1. When an object is opened in detail view, the plugin identifies all object types that have linked fields pointing to the current object's type
2. For each configured object type, it searches for objects where the linked field contains the current object's global ID
3. Results are grouped by object type (and optionally by field) and displayed with pagination

### Search Behavior

- Maximum of 1000 results per object type/field combination
- Results are sorted alphabetically by standard text within each group
- Groups are sorted alphabetically by object type name (and field name if Show Fields is enabled)

### Limitations

- Only displays in detail view mode (not in editor or other views)
- Cannot be used inside nested tables
- Searches only through fields visible in expert search mode

## File Structure

```
easydb-custom-mask-splitter-detail-linked-plugin/
├── src/
│   └── webfrontend/
│       ├── DetailLinkedMaskSplitter.coffee    # Main plugin logic
│       └── scss/
│           └── detail-linked-mask-splitter.scss   # Styles
├── l10n/
│   └── custom-mask-splitter-detail-linked.csv     # Translations
├── manifest.yml                                    # Plugin manifest
├── Makefile                                        # Build configuration
└── README.md
```

## Development

### Prerequisites

- Node.js and npm (for CoffeeScript compilation)
- Make

### Building

```sh
# Full build (code + localization)
make all

# Code only
make code

# Clean build artifacts
make clean
```

### Localization

The plugin supports multiple languages. Translations are managed in `l10n/custom-mask-splitter-detail-linked.csv`.

Supported languages:
- English (en-US)
- German (de-DE)
- Danish (da-DK)
- Finnish (fi-FI)
- Swedish (sv-SE)
- French (fr-FR)
- Italian (it-IT)
- Spanish (es-ES)

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Links

- **Repository**: https://github.com/programmfabrik/easydb-custom-mask-splitter-detail-linked-plugin
- **easydb Documentation**: https://docs.easydb.de
- **Fylr Documentation**: https://docs.fylr.io
