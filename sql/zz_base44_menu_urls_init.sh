#!/bin/sh
# Base44 sandbox: point the console's dashboard menu entries at this environment's public
# host ports. The seeded menus say http://localhost:<port> (112 Nacos控制台 :8848/nacos,
# 113 Admin控制台 :9100/login, 116 系统接口 :8080/swagger-ui/index.html), and localhost in a
# browser is the *viewer's* own machine, so those pages never open. Menu 111 (Sentinel控制台
# :8718) is hidden instead: no Sentinel dashboard runs in this stack.
#
# This file sits in sql/ so it rides the single `./sql:/docker-entrypoint-initdb.d:ro` mount:
# a second mount inside that read-only directory cannot be created (Docker fails the container
# with "read-only file system"). Its name sorts after the seed files, so the MySQL entrypoint
# sources it during the initdb phase of a first boot — after ry_20260417.sql has created
# sys_menu, and with the server reachable on its unix socket. Init scripts run ONLY when the
# data volume is empty; AGENTS.md explains how to re-apply these statements to an existing
# volume.
#
# No-op when the variable is unset (i.e. outside the sandbox), and never fatal: a failure
# here must not abort the seed.

if [ -z "$BASE44_PUBLIC_HOST_SUFFIX" ]; then
  echo "BASE44_PUBLIC_HOST_SUFFIX unset - leaving the seeded dashboard menu URLs alone"
else
  if mysql --protocol=socket --socket="${SOCKET:-/var/run/mysqld/mysqld.sock}" \
       -uroot --password="$MYSQL_ROOT_PASSWORD" ry-cloud <<SQL
UPDATE sys_menu SET path = 'https://8088-$BASE44_PUBLIC_HOST_SUFFIX/'                      WHERE menu_id = 112;
UPDATE sys_menu SET path = 'https://9100-$BASE44_PUBLIC_HOST_SUFFIX/login'                 WHERE menu_id = 113;
UPDATE sys_menu SET path = 'https://8080-$BASE44_PUBLIC_HOST_SUFFIX/swagger-ui/index.html' WHERE menu_id = 116;
UPDATE sys_menu SET visible = '1'                                                          WHERE menu_id = 111;
SQL
  then
    echo "dashboard menus point at the public host ports of this sandbox"
  else
    echo "WARNING: could not point the dashboard menus at this sandbox's public hosts"
  fi
fi
