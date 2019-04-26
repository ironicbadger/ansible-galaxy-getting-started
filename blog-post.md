# Getting started with Ansible Galaxy roles

Ansible Galaxy is a great resource to save you a ton of time and promote code reuse. It's a 'marketplace' of Ansible roles you may freely download and use (accordingly to their license of course) across your systems. This article will cover some of the tips and tricks I learned as a Red Hat consultant working on this stuff every day, it's not perfect and there are probably better ways but here's my take.

Full code examples are provided in this Github repo.

## Ansible building blocks

To get started with Ansible is really easy. First we should probably understand a little of what Ansible is trying to accomplish. Ansible roles are a collection of tasks which execute modules designed to bring a system to a desired state. Take the following task for example, it executes the `copy` module.

```
- name: copy samba configuration file
  copy:
    src: etc/smb.conf
    dest: /etc/samba/smb.conf
  notify: restart samba
```

Hopefully just by reading this task you can tell exactly what it does. It copies a file from the host running the Ansible playbook (the name given to a group of roles) from a relative path to the playbook to an absolute path on the target system. Once this is done we notify a handler which is a small piece of code that lives in the `handlers` folder to restart the samba service to pick up the new config file. Handlers are useful, but a little more advanced so don't worry if you don't need them yet but here's an example of a handler to restart samba.

```
- name: restart samba
  service:
    name: samba
    state: restarted
    enabled: true
```

This is functionally the equivalent of `systemctl restart samba && systemctl enable samba`.

Ansible is idempotent. Meaning it will only execute these tasks if it needs to. It will compare the files and if they match it will not perform any actions. Neat!

## Code reuse

When configuring a Linux system it's pretty likely that a large chunk of what you're doing has been done before by someone else, somewhere else. Wouldn't it be nifty if you could just reuse their work and expertise?

For example, I'm not a security expert but despite this I have spent a fair amount of time trawling through various server config files to configure SSH in a particular way. It would be so much better if someone else who is a subject matter expert on SSH hardening wrote a role that I could plug my variables into and reuse. Well, we're in luck. This is *exactly* what this post and Ansible Galaxy is designed to enable you to do.

## Getting started

Take a look in the example code Github repository I posted along with this article. In there you'll see quite a few files, let's break them down.

  * `ansible.cfg` - A number of important Ansible variables live in here
  * `hosts` - Ansible looks here to determine which groups hosts belong to (important for variable assignment)
  * `Makefile` - optional but `make site` beats a long, unwieldy `ansible-playbook` command
  * `requirements.yml` - The roles you'd like to install locally from Ansible Galaxy
  * `site.yml` - The playbook (collection of roles) to be executed
  * `.gitignore` - Ensures installed Ansible Galaxy playbooks aren't included in your git repo

One of the neater tricks I learned over the last year was using `roles_path = $PWD/galaxy_roles:$PWD/roles` in `ansible.cfg`. This forces Ansible Galaxy to install the roles into the playbook working directory instead of some random location on your system. It allows for multiple projects using multiple different versions of these roles without them interfering with one another. There are some other neat tricks in this file but for now, I'll let you Google those options yourself.

In order to consume other peoples roles you must first populate `requirements.yml` thus:

```
# requirements.yml
- src: ironicbadger.ansible_role_packages
- src: geerlingguy.docker
- src: geerlingguy.security
- src: rossmcdonald.telegraf
```

One line per entry. `make reqs` (assuming you're using a Makefile, if not open up mine for the syntax you need) is all that's required to install these roles for Ansible to use.

Next we need to configure `site.yml` to actually use these roles. Note that you can use a mixture of both local and Ansible Galaxy based roles in the same playbook. Again, see the associated repository for full examples but here's a snippet:

```
# site.yml
  - hosts: example
    roles:
      - role: geerlingguy.docker
        tags: docker
      - role: ironicbadger.ansible_role_packages
        tags: packages
      - role: ironicbadger.ansible_role_hddtemp
      - role: rossmcdonald.telegraf
      #- role: ktz-disks #an example of a good use case for a local role vs galaxy role
```

Finally, you need to add your variables to the `group_vars` file which matches the inventory host group you placed your host into in `hosts`. Sounds complicated but it's easy really. You put your host into the `example` group in the inventory thus:

```
[example]
example.host.org
```

By being a member of the `example` host group `example.host.org` inherits the `group_vars/example` variables. There are many ways to define variables in Ansible but I find this to be particularly powerful. In the `group_vars/example` file add the variables that the Galaxy Role you're consuming exposes. You'll need to read the documentation for each role to figure this out but that's a lot less effort than writing one! I've included quite a few examples in the associated Github repo for this post to get you started.

## Execute

Let's recap quickly.

* Set an appropriate role path in `ansible.cfg`
* Configure your upstream dependencies in `requirements.yml`
* `make reqs` or `ansible-galaxy install -r requirements.yml` to install those upstream dependencies
* Configure your playbook in `site.yml` to tell Ansible what you want to run against each host
* Configure your inventory file `hosts` with appropriate groupings for variable inheritance
* `group_vars/example` contains the variables to be used for hosts in this inventory host group

Phew! Now we're ready to go with all this configured execute

    make example

    # or

    ansible-playbook -i hosts -u alex -b site.yml --limit example

A few minutes later you'll have a fully configured server.

## Ongoing usage

Upstream role authors will likely publish updates to their roles as time progresses. You can consume these by updating your local copy of their roles with the `ansible-galaxy` command in the example Makefile. There's probably a better way than the `--force` but this works well enough for me so I never bothered to figure anything else out!

## Conclusion

That's really all there is to using roles from Ansible Galaxy. I hope you found something useful in this post and that I've enabled you on the path to code reuse and using the power of Ansible.