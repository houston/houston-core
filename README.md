# Houston Core [![Code Climate](https://codeclimate.com/github/houston/houston-core.png)](https://codeclimate.com/github/houston/houston-core)

##### Mission Control for your projects and team

Houston interfaces with your version-control, ticket-tracking, continuous integration, and other systems to stitch together a picture of your projects and teams.

It makes it easy to set up **triggers** and **notifications** like:

 - Resolving an exception report when a commit that mentions it is deployed
 - Slacking team members when a pull request is labeled or unlabeled
 - Notifying a committer when their commit breaks a test

And it provides a foundation for custom views like **dashboards** and **reports**.

Houston is also extensible through **modules**.



## Getting Started with Houston

##### System Requirements

To use Houston, you must have

 - [Ruby 2.0+](https://www.ruby-lang.org/en/downloads)
 - [Postgres 9.3+](http://www.postgresql.org/download)

##### Hello World

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
