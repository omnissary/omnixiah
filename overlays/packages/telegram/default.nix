_self: super: {
  telegram = super.callPackage (
    { telegram-desktop, ... }:
    telegram-desktop.override {
      unwrapped = telegram-desktop.unwrapped.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./0001-Disable-sponsored-messages.patch
          ./0002-Disable-saving-restrictions.patch
          ./0003-Disable-invite-peeking-restrictions.patch
          ./0004-Disable-accounts-limit.patch
          ./0005-Option-to-disable-stories.patch
        ];
      });
    }
  ) { };
}
