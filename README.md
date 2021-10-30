# Paradise Website

This website was built roughly in 2015/2016.

## Setup

- Install dependencies `bundle install --path vendor/bundle`
- Run Jekyll dev server `bundle exec jekyll serve`

## Architecture

The project is a stand alone Jekyll project using barebones coffeescript & sass.

It is administered manually as any other Jekyll project, but we do use a helper service called siteleaf.com to provide a better UX for content authors.

## Content entry

Content is entered via the Jekyll data files in the \_data directory, or via the Siteleaf admin.

Users must know which module types are possible, and what values to input into each field. This can be done by looking at other projects in the Siteleaf admin, or in the `_data/X.markdown` files.

Much content is hard coded and requires a developer.

### Video

To insert video, use Vimeo, and paste the entire embed script into the "embed" key of module `type: video`

    - type: video
    embed: <div>...
