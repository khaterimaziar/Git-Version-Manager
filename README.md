# 🚀 Git Version Manager

A Bash script for simplified and organized version management in Git projects.  
Works with any type of project (software, research, data science, etc.) and includes special support for **Jupyter Notebooks**.

---

## ✨ Features
- 📓 **Automatic notebook versioning**  
  Detects the latest notebook version and creates the next automatically  
  *(e.g., `Model(v1).ipynb → Model(v2).ipynb`)*.
- 🌿 **Version branches** for each release.
- 📝 **Version & description tracking** in files.
- 🏷️ **Git tagging** for easy reference.
- 🔄 **Rollback support** if something breaks.
- ⚙️ **Interactive fix mode** for common issues.

---

## 🚀 Usage
Run the script inside your Git project:

```bash
./Git_Management.sh v1 "Initial release"

# Start with version v1
./Git_Management.sh v1 "First working version"

# Create v2 with description
./Git_Management.sh v2 "Improved performance"

# Rollback to a previous version
./Git_Management.sh --rollback v2


📂 Suitable For
💻 Software development projects
📑 Research and academic projects
📊 Data science / machine learning workflows
🗂️ Any Git-managed project with version-tracked files
📖 How It Works
Detects the latest version of notebooks (if available).
Creates a copy with the next version name.
Commits changes and creates a new Git branch.
Updates files with version info.
Pushes everything to remote (requires internet access).
Adds a Git tag for easier reference.
Note:

The script handles files with different extensions, but if you have files without extensions or with multiple dots in the name, read the docs in the script for the exact handling rules.


👨‍💻 Author
Maziar Khateri
Medical Imaging & Data Analysis | Git Enthusiast

⭐ If you find this useful, please consider starring the repo!

