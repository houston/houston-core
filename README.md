# Houston [![Code Climate](https://codeclimate.com/github/houstonmc/houston.png)](https://codeclimate.com/github/houstonmc/houston)

### Mission Control for your projects and teammates.

Houston interfaces with your version-control, ticket-tracking, continuous integration, and other systems to stitch together a picture of your projects and teams.
 
<table>
  <tr>
    <td align="center" vertical-align="top">
      <a href="http://houstonmc.github.com/houston/images/screenshots/kanban.png" target="_blank" title="Kanban">
        <img src="http://houstonmc.github.com/houston/images/screenshots/kanban.png" width="180" alt="Kanban" />
      </a>
    </td>
    <td align="center" vertical-align="top">
      <a href="http://houstonmc.github.com/houston/images/screenshots/testing-conversation.png" target="_blank" title="Testing Workflow">
        <img src="http://houstonmc.github.com/houston/images/screenshots/testing-conversation.png" width="180" alt="Testing Workflow" />
      </a>
    </td>
    <td align="center" vertical-align="top">
      <a href="http://houstonmc.github.com/houston/images/screenshots/new-release.png" target="_blank" title="Reports">
        <img src="http://houstonmc.github.com/houston/images/screenshots/new-release.png" width="180" alt="Reports" />
      </a>
    </td>
    <td align="center" vertical-align="top">
      <a href="http://houstonmc.github.com/houston/images/screenshots/weekly-report-commits.png" target="_blank" title="Reports">
        <img src="http://houstonmc.github.com/houston/images/screenshots/weekly-report-commits.png" width="180" alt="Reports" />
      </a>
    </td>
  </tr>
  <tr>
    <th>Kanban</th>
    <th>Testing Workflow</th>
    <th>Automatic Release Notes</th>
    <th>Reports</th>
  </tr>
</table>



## Vision

Houston does not intend to become a ticket-tracking system or continuous integration server. It's goal is to glue those systems together and synthesize information from them. Houston has three parts:

 1. A model of your projects and teams
 2. Adapters for various version-control, ticket-tracking, and other systems
 3. Custom views that synthesize that information

You should pick a ticket-tracking system or a continuous integration server based on your teams needs&mdash;or your company's needs&mdash;but then be able to extend it as you wish. Houston is a framework for just that!



## Features

The following are examples of how Houston can be used:

 - **Kanban** allows you define stages for tickets and then depicts how all of your tickets, across projects, fall into those stages.
 - **Testing Report** collects tickets awaiting QA from multiple projects, and shows the progress and evolution of testing
 - **Release Notes** are generated automatically from your commit messages, and can be configured to automatically close tickets when released
 - **Scheduler** shows you tickets that need effort and value estimates and generates to-do lists from them based on your queuing discipline
 - **CI** can be configured to trigger CI jobs and publish the results upon version-control events



## Architecture

### Models

Four models are central to Houston:

 - **Project** which ties together a slug, color, and different adapters with a project
 - **User** which has a role and is tied to different permissions and notifications
 - **Ticket** a generic concept of a ticket
 - **Commit** a generic concept of a commit

### Adapters

Houston uses adapters to support multiple systems. There are three right now:
 - **TicketTracking**: `Unfuddle` and `None` supported
 - **VersionControl**: `Git` and `None` supported
 - **CI**: `Jenkins` and `None` supported

### Configuration

The specific details of Houston's operation are described in config/config.rb ([example](https://github.com/houstonmc/houston/blob/master/config/config.sample.rb)).



## Roadmap

 1. Finish extracting existing features into engines like [houston-scheduler](https://github.com/houstonmc/houston-scheduler)
 2. Extract Errbit and New Relic support to adapters
 3. Expand implementations of adapters as needed

See [TODO.mdown](https://github.com/houstonmc/houston/blob/master/TODO.mdown)
