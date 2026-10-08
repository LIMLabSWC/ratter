# BControl Documentation

Jekyll-based documentation site for BControl.

## How Jekyll Works

**The Process:**
```
Your Markdown Files → Jekyll Processing → HTML Website
```

- **You write:** Markdown files (`.md`)
- **Jekyll reads:** Your Markdown + Layout templates
- **Jekyll generates:** Complete HTML website in `_site/`
- **Result:** Professional documentation site with navigation

**Key Concept:** You edit Markdown, Jekyll automatically creates a complete website with consistent navigation and styling.

## Local Development Setup

### Prerequisites
```bash
# Install Ruby and dependencies
sudo apt update
sudo apt install -y ruby-full build-essential zlib1g-dev

# Configure Ruby environment
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Install Jekyll and Bundler
gem install jekyll bundler
```

### Running Locally
```bash
# Navigate to docs directory
cd docs

# Install dependencies
bundle install

# Serve locally (auto-regenerates on file changes)
bundle exec jekyll serve
```

**Local URL:** `http://127.0.0.1:4000/ratter/`

### Build for Production
```bash
# Generate static site
bundle exec jekyll build
```

## GitHub Pages Deployment

**Automatic Deployment:**
1. Push your changes to GitHub
2. GitHub detects Jekyll files (`_config.yml`, `_layouts/`, etc.)
3. GitHub automatically runs `jekyll build`
4. Site goes live at `https://limlabswc.github.io/ratter/`

**No manual deployment needed!** GitHub Pages handles everything automatically.

## Project Structure

```
docs/
├── _config.yml              # Jekyll configuration
├── _layouts/
│   └── default.html         # Main layout with navigation
├── _site/                   # Generated website (auto-created)
├── index.md                 # Homepage
├── guides/                  # User guides
│   ├── protocol-writers-guide.md
│   ├── solo-core-guide.md
│   └── water-valve-tutorial.md
├── architecture/            # System architecture docs
│   ├── system-overview.md
│   ├── system-architecture.md
│   └── legacy-architecture.md
├── technical/               # Technical references
│   ├── fsm-documentation.md
│   ├── staircases.md
│   └── svn_update_process.md
├── protocols_overview.md    # Protocols documentation
├── Gemfile                  # Ruby dependencies
└── README.md               # This file
```

## Navigation System

**Features:**
- **Sticky top navigation** - Always visible while scrolling
- **Dropdown menus** - Organized by section (User Guides, System Architecture, etc.)
- **Responsive design** - Works on desktop and mobile
- **Consistent across all pages** - Every page gets the same navigation

**Navigation Structure:**
- **Home** - Returns to homepage
- **User Guides** - Protocol Writer's Guide, Solo Core Guide, Water Valve Tutorial
- **System Architecture** - System Overview, Architecture docs, Legacy notes
- **Technical References** - FSM Documentation, Staircase Algorithms, SVN Process
- **Protocols** - Protocols Overview, Training Protocols, Browse All Protocols

## Development Workflow

```
Edit Markdown Files → Test Locally → Push to GitHub → Live on GitHub Pages
```

**Local Testing:**
- ✅ Test navigation works
- ✅ Check styling looks good
- ✅ Verify all links work
- ✅ Make sure content displays correctly

**GitHub Deployment:**
- ✅ Push your changes
- ✅ GitHub automatically builds and deploys
- ✅ Site goes live with same navigation and styling

## Adding New Content

**To add a new documentation page:**
1. Create a new `.md` file in the appropriate directory
2. Add front matter at the top:
   ```yaml
   ---
   title: Your Page Title
   layout: default
   ---
   ```
3. Write your content in Markdown
4. Jekyll automatically includes it in the navigation

**To update navigation:**
- Edit `_layouts/default.html` to add new menu items
- Use `{{ '/path/to/page' | relative_url }}` for internal links

## Styling and Layout

**Layout System:**
- `_layouts/default.html` - Main template with navigation
- `{{ content }}` - Where your Markdown content gets inserted
- All pages automatically get consistent styling and navigation

**Custom Styling:**
- CSS is embedded in the layout template
- Responsive design with mobile support
- Professional documentation styling

## Benefits

**For Content Creators:**
- Write in simple Markdown
- No HTML knowledge required
- Automatic website generation
- Consistent styling across all pages

**For Users:**
- Professional documentation site
- Easy navigation between sections
- Mobile-friendly design
- Fast loading and reliable hosting

## Troubleshooting

**Common Issues:**
- **Links not working:** Make sure to use `{{ '/path' | relative_url }}` for internal links
- **Styling issues:** Check that CSS is properly embedded in the layout
- **Build errors:** Run `bundle install` to ensure all dependencies are installed

**Getting Help:**
- Check Jekyll documentation: https://jekyllrb.com/docs/
- GitHub Pages documentation: https://docs.github.com/en/pages
