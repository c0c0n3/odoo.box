Odoo Box From Scratch
---------------------
> Bootstrapping a fully-fledged Odoo server on NixOS.

How do you build an Odoo server from scratch using our Flake? The
high-level procedure is pretty straightforward if you're familiar
with Nix:

1. Provision the hardware.
2. Install a bare-bones NixOS.
3. Use our Flake to install an Odoo bootstrap config to load prod
   data.
4. Use our Flake to deploy the Odoo prod config.

But as usual, the devil is in the details. So we've put together
two detailed, step-by-step guides to help you bootstrap your box:

- [Dev VM][devm]. Building a Qemu VM that's basically a prod clone.
  You use this for local testing and development.
- [AWS EC2][aws]. Building an EC2 prod instance. That's where you
  run the show.

Both guides reference a separate step-by-step procedure to migrate
Odoo prod data from the old K8s cluster to the new NixOS Odoo server

- [Loading Odoo Data][odoo].




[aws]: ./aws.md
[devm]: ./dev-vm.md
[odoo]: ./odoo-data.md
