# Custom Mask Splitter: Show References

This project implements a custom mask splitter plugin for easydb. It displays a list of all objects that reference the currently viewed object in the detail view. The plugin supports multiple display modes (standard, short, and text) as well as filtering by object types and inheritance inclusion.

## Compatibility

- **Fylr Integration:** Fully compatible with Fylr.
- **easydb 5:** Tested and supported with easydb version 5. (Inheritance and nested fields are not supported in easydb5)

## Installation

To use the source code, follow these steps:

- **Clone or pull the repository** into the plugin directory of your instance.
- Run the build and deployment command:
    ```sh
    make all
    ```
- **Restart easydb.** If you are using Fylr, go to the plugin manager and activate the plugin.

## Usage

Once the plugin is activated:

- Navigate to the Mask Editor.
- Select the mask where you want to add the plugin.
- Add the mask splitter using the "+" button in the Mask Editor.
- Configure the mask splitter by selecting the object types in which to search for references to the current object and customize how the references are displayed.
