_final: prev: {
  vhost-device-vsock = prev.vhost-device-vsock.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      # Require vsock_loopback, which is unavailable in Nix build sandboxes.
      "--skip=thread_backend::tests::test_vsock_thread_backend_vsock"
      "--skip=vhu_vsock_thread::tests::test_vsock_thread_vsock_backend"
    ];
  });
}
