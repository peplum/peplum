# Peplum -- Distributed parallel computing made easy

Peplum is a distributed parallel processing solution powered by [Cuboid](https://github.com/qadron/cuboid) -- copyright
[Ecsypno Single Member P.C.](https://ecsypno.com).

Its basic function is to distribute workloads and deliver abstract payloads across multiple machines and thus parallelize 
otherwise time consuming tasks.

Basically, Peplum allows you to combine the resources of multiple machines and build a Beowulf (or otherwise) cluster/super-computer.

Being written in [Ruby](https://www.ruby-lang.org/en/), you can deliver the payload of OS applications, Ruby code, C/C++/Rust 
extensions and package your Peplum app as a [gem](https://guides.rubygems.org/what-is-a-gem/).

It can be used for educational/research purposes or to build commercial solutions in the cloud or on-premise or even used 
to speed up your routine at home.

Peplum can be deployed in a range of use-cases, such as running simulations, [network mapping/security scans](https://github.com/peplum/peplum-nmap),
[password cracking/recovery](https://github.com/peplum/peplum-john) or just encoding your collection of music and video, etc.

## Goal

The goal of the project is for Peplum to be to distributed parallel computing development, what Sinatra or Rails is for
web application development.

An abstract, application-centric, straightforward and simple framework that get's out of your way and let's you accomplish your goals.

Basically, the project's essential goal is to allow users to turn applications and code into _super_ version of themselves with ease.

## Provides

* Freedom from system dependencies and configuration -- no DBs, etc. required.
* `Services::SharedHash` accessible via `Application.shared_hash` -- Distributed key-value store, used as a DB, cache and/or message broker.
  * Optionally, applications can add more shared hash services if they require.
* Support for custom RPC and/or REST APIs/services.
  * REST services should be designed to be only client facing, as RPC is the default and preferred medium for internal communication.

## Creating a Peplum application

See [Peplum::Template](https://github.com/peplum/template).

## Users

* [Peplum::Nmap](https://github.com/peplum/peplum-nmap) -- Distributed network mapper/security scanner powered by [nmap](https://nmap.org).
* [Peplum::John](https://github.com/peplum/peplum-john) -- Distributed password cracker powered by [John the Ripper](https://www.openwall.com/john/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/peplum/peplum.

## Funding

Peplum is a [Peplum](https://github.com/peplum/) project and as such funded by [Ecsypno Single Member P.C.](https://ecsypno.com).
