// Copyright 2013 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library oe_setup;

import 'dart:io';
import 'package:grinder/grinder.dart';

// The directory name we will clone to.
// should be different depending on chip name.
// ie, for m14tv, it should be "beehive". On the other hand, for lm15u,
// "beehive_lm15u".
var _directory_name = "beehive";
var _chip_name = "m14tv";

void set_m15u(GrinderContext context) {
  _directory_name = "beehive_lm15u";
  _chip_name = "lm15u";
}

void set_h15(GrinderContext context) {
  _directory_name = "beehive_h15";
  _chip_name = "h15";
}

void main([List<String> args]) {
  task('clean', clean);
  task('clone_oe', clone_oe);
  task('ccc_clone', ccc_clone);
  task('ccc_clone_h15_badland', ccc_clone_h15);
  task('build_flash', build_flash, ['clone_oe']);
  task('build_nfs', build_nfs, ['clone_oe']);
  task('build_flash_dvb', build_flash_dvb, ['clone_oe']);
  task('build_nfs_dvb', build_nfs_dvb, ['clone_oe']);
//---------------------------------------------------
  task('set_h15', set_h15);
  task('h15_clone_oe', clone_oe, ['set_h15']);
  task('h15_build_flash', build_flash, ['set_h15', 'clone_oe']);
  task('h15_build_nfs', build_nfs, ['set_h15', 'clone_oe']);
  task('h15_build_flash_dvb', build_flash_dvb, ['set_h15', 'clone_oe']);
  task('h15_build_nfs_dvb', build_nfs_dvb, ['set_h15', 'clone_oe']);
//---------------------------------------------------
  task('set_m15u', set_m15u);
  task('lm15u_clone_oe', clone_oe, ['set_m15u']);
  task('lm15u_build_flash', build_flash, ['set_m15u', 'clone_oe']);
  task('lm15u_build_nfs', build_nfs, ['set_m15u', 'clone_oe']);
  task('lm15u_build_flash_dvb', build_flash_dvb, ['set_m15u', 'clone_oe']);
  task('lm15u_build_nfs_dvb', build_nfs_dvb, ['set_m15u', 'clone_oe']);
//---------------------------------------------------
  task('lm15u_clean_hybridtv', clean_hybridtv, ['set_m15u']);

  startGrinder(args);
}

void clean(GrinderContext context) {
  _runCommandSync(context, 'rm -rf beehive');
}

void clean_hybridtv(GrinderContext context) {
  Directory originalDirectory = Directory.current;

  Directory.current =
      joinDir(Directory.current, ['${_directory_name}', 'BUILD-${_chip_name}']);
  context.log(Directory.current.path);
  context.log("## Start bitbake build ##");
  _runBashCommandSync(context, 'source bitbake.rc;bitbake -c cleanall hybridtv');

  Directory.current = originalDirectory;
}

void clone_oe(GrinderContext context) {
  if (joinDir(Directory.current, ['${_directory_name}']).existsSync()) {
    context.log("${_directory_name} directory is already exist. Stop cloning.");
    return;
  }

  context.log("## Start clone OE Repository ##");
  _runCommandSync(context,
    'git clone ssh://polar.lge.com:29438/starfish/build-starfish.git ${_directory_name}');
  _runCommandSync(context, 'cp ./tools/webos-local.conf ./${_directory_name}');

  Directory originalDirectory = Directory.current;
  Directory.current = joinDir(Directory.current, ['${_directory_name}']);
  _runCommandSync(context, 'git checkout @beehive4tv');
  context.log("## Run MCF ##");
  _runCommandSync(context,
      './mcf -b 16 -p 16 ${_chip_name} --premirror=file:///starfish/downloads');
  Directory.current = originalDirectory;
}

void ccc_clone(GrinderContext context) {
  _runCommandSync(context, 'rm -rf ccc');
  context.log("## Start clone OE Repository ##");
  _runCommandSync(context,
    'git clone ssh://polar.lge.com:29438/starfish/build-starfish.git ccc');

  Directory originalDirectory = Directory.current;
  Directory.current = joinDir(Directory.current, ['ccc']);
  _runCommandSync(context, 'git checkout @beehive4tv');
  context.log("## Run MCF ##");
  _runCommandSync(context,
      './mcf -b 16 -p 16 ${_chip_name} --premirror=file:///starfish/downloads');
  Directory.current = originalDirectory;
}

void ccc_clone_h15(GrinderContext context) {
  _runCommandSync(context, 'rm -rf ccc_h15');
  context.log("## Start clone OE Repository ##");
  _runCommandSync(context,
    'git clone ssh://polar.lge.com:29438/starfish/build-starfish.git ccc_h15');

  Directory originalDirectory = Directory.current;
  Directory.current = joinDir(Directory.current, ['ccc_h15']);
  _runCommandSync(context, 'git checkout @17.badlands.h15');
  context.log("## Run MCF ##");
  _runCommandSync(context,
      './mcf -b 16 -p 16 h15 --premirror=file:///starfish/downloads');
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

  Directory.current =
      joinDir(Directory.current, ['${_directory_name}', 'BUILD-${_chip_name}']);
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

