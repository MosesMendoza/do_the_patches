#!/bin/sh

# script to auto-re-do the remaining patches
# use when you built the packages wrong like me
#
# 1.1-el5-2.6.4
# 1.1-el6-2.6.4
# 1.2-el5-2.6.7
# 1.2-el6-2.6.7
# 2.0-el5-2.7.9
# 2.0-el6-2.7.9

# go through the build for every version
combos="1.1-el5-2.6.4 1.1-el6-2.6.4 1.2-el5-2.6.9 1.2-el6-2.6.9 2.0-el5-2.7.9 2.0-el6-2.7.9"

# make sure we start in the right place
cd /home/moses

for combo in ${combos} ; do
  # grok the version
  version=`echo ${combo} | cut -d '-' -f 2`
  # find the source rpm and extract to rpmbuild dir. Assume the patched version is in a "patch" folder
  rpm -i ${combo}/patched/*
  # generate a new source rpm for mock. if el5, use rpmbuild-md5, otherwise just rpmbuild
  if ( grep -r --include="*.el5*src.rpm" . ${combo}/patched > /dev/null ) ; then
    rpmbuild-md5 -bs --nodeps /home/moses/rpmbuild/SPECS/*
  else
    rpmbuild -bs --nodeps /home/moses/rpmbuild/SPECS/*
  fi
  # clean out the build package repo
  rm /home/moses/localrepo/*.rpm

  # populate with packages
  pe_source=`ls ${combo}/repopackages/`
  tar -xf ${combo}/repopackages/${pe_source} -C ${combo}/repopackages/
  pe_dir=`find ${combo}/repopackages/ -maxdepth 1 -mindepth 1 -type d`
  pe_dir=`basename $pe_dir`
  # of course there are no naming conventions
  for_string=`ls ${combo}/repopackages/${pe_dir}/packages/`
  cp ${combo}/repopackages/${pe_dir}/packages/${for_string}/*.rpm /home/moses/localrepo/

  # remove that directory in case we need to do this again..
#  rm -r ${combo}/repopackages/${pe_dir}

  # update the repo
  createrepo -d --update /home/moses/localrepo/

  # rebuild using the appropriate mock configuration
  mock -r pupent-$version-i386 --configdir mockconfigs /home/moses/rpmbuild/SRPMS/*

  # get the finished rpms
  mkdir -p /home/moses/finished_rpms/$combo
  cp -r /var/lib/mock/pupent-$version-i386/result/* /home/moses/finished_rpms/$combo/
  rm /home/moses/finished_rpms/$combo/*.log

  # clean out the rpmbuild directories
  rm -rf /home/moses/rpmbuild/SOURCES/*
  rm -rf /home/moses/rpmbuild/SRPMS/*
  rm -rf /home/moses/rpmbuild/RPMS/*
  rm -rf /home/moses/rpmbuild/SPECS/*
  rm -rf /home/moses/rpmbuild/BUILD/*
  rm -rf /home/moses/rpmbuild/BUILDROOT/*
done

