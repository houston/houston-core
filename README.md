# Houston Core

[![Gem Version](https://badge.fury.io/rb/houston-core.svg)](https://rubygems.org/gems/houston-core)
[![Code Climate](https://codeclimate.com/github/houston/houston-core.svg)](https://codeclimate.com/github/houston/houston-core)
[![Build Status](https://travis-ci.org/houston/houston-core.svg)](https://travis-ci.org/houston/houston-core)

Mission Control for your projects and teams.

Houston interfaces with your version-control, ticket-tracking, continuous integration, and other systems to stitch together a picture of your projects and teams.

It makes it easy to set up **[triggers](https://github.com/houston/houston-core/wiki/Triggers)** to perform tasks like:

 - Resolving an exception report when a commit that mentions it is deployed
 - Slacking team members when a pull request is labeled or unlabeled
 - Notifying a committer when their commit breaks a test

And it provides a foundation for custom views like **dashboards** and **reports**.

Houston is also extensible through **[Modules](https://github.com/houston/houston-core/wiki/Modules)** like:

 - [Houston::Slack](https://github.com/houston/houston-slack), which gives Houston the ability to listen to messages—and respond—via Slack
 - [Houston::Alerts](https://github.com/houston/houston-alerts), which gives Houston the ability to treat tasks from arbitrary sources as a unified queue
 - [Houston::Feedback](https://github.com/houston/houston-feedback), which adds a view for quickly importing, tagging, and searching customer feedback
 - [Houston::Roadmaps](https://github.com/houston/houston-roadmaps), which adds a view for planning project milestones


## Requirements

To use Houston, you must have

 - [Ruby 2.0+](https://www.ruby-lang.org/en/downloads)
 - [Postgres 9.4+](http://www.postgresql.org/download)


## Getting Started

 1. Install houston-core

    ```
    gem install houston-core
    ```

 2. Generate an instance of Houston

    ```
    houston new my-houston
    cd my-houston
    ```

 3. Modify `config/database.yml` to connect to your database (See [the Rails Guide](http://guides.rubyonrails.org/configuring.html#configuring-a-database) for examples)
 4. Set up your database

    ```
    bin/setup
    ```

 5. Start Houston

    ```
    bundle exec rails server
    ```


## License

Houston is released under the [MIT License](http://www.opensource.org/licenses/MIT).
