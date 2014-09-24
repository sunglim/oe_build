// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library oe_setup;

import 'dart:io';
import 'package:grinder/grinder.dart';

void main([List<String> args]) {
  task('clean', clean);
  task('clone_oe', clone_oe);
  task('build_flash', build_flash, ['clone_oe']);
  task('build_nfs', build_nfs, ['clone_oe']);
  task('build_flash_dvb', build_flash_dvb, ['clone_oe']);
  task('build_nfs_dvb', build_nfs_dvb, ['clone_oe']);

  startGrinder(args);
}

void clean(GrinderContext context) {
  _runCommandSync(context, 'rm -rf beehive');
}

void clone_oe(GrinderContext context) {
  if (joinDir(Directory.current, ['beehive']).existsSync()) {
    context.log("beehive directory is already exist. Stop cloning.");
    return;
  }

  context.log("## Start clone OE Repository ##");
  _runCommandSync(context,
    'git clone ssh://polar.lge.com:29438/starfish/build-starfish.git beehive');
  _runCommandSync(context, 'cp ./tools/webos-local.conf ./beehive');

  Directory originalDirectory = Directory.current;
  Directory.current = joinDir(Directory.current, ['beehive']);
  _runCommandSync(context, 'git checkout @beehive4tv');
  context.log("## Run MCF ##");
  _runCommandSync(context,
      './mcf -b 16 -p 16 m14tv --premirror=file:///starfish/downloads');
  Directory.current = originalDirectory;
}

void build_flash(GrinderContext context) {
  _build(context, "starfish-atsc-flash");
}

void build_nfs(GrinderContext context) {
  _build(context, "starfish-atsc-nfs");
}

void build_flash_dvb(GrinderContext context) {
  _build(context, "starfish-dvb-flash");
}

void build_nfs_dvb(GrinderContext context) {
  _build(context, "starfish-dvb-nfs");
}

void _build(GrinderContext context, String flashOrNfs) {
  Directory originalDirectory = Directory.current;

  Directory.current = joinDir(Directory.current, ['beehive', 'BUILD-m14tv']);
  context.log(Directory.current.path);
  context.log("## Start bitbake build ##");
  _runBashCommandSync(context, 'source bitbake.rc;bitbake ${flashOrNfs}');

  Directory.current = originalDirectory;
}

void _runBashCommandSync(GrinderContext context, String command, {String cwd}) {
  context.log(command);

  ProcessResult result =
      Process.runSync('/bin/bash', ['-c', command], workingDirectory: cwd);

  if (result.stdout.isNotEmpty) {
    context.log(result.stdout);
  }

  if (result.stderr.isNotEmpty) {
    context.log(result.stderr);
  }

  if (result.exitCode > 0) {
    context.fail("exit code ${result.exitCode}");
  }
}

void _runCommandSync(GrinderContext context, String command, {String cwd}) {
  context.log(command);

  ProcessResult result =
      Process.runSync('/bin/sh', ['-c', command], workingDirectory: cwd);

  if (result.stdout.isNotEmpty) {
    context.log(result.stdout);
  }

  if (result.stderr.isNotEmpty) {
    context.log(result.stderr);
  }

  if (result.exitCode > 0) {
    context.fail("exit code ${result.exitCode}");
  }
}

