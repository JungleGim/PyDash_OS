Most of the packages that were used by Buildroot to produce the image files,
including Buildroot itself, have open-source licenses. It is your
responsibility to comply to the requirements of these licenses.
To make this easier for you, Buildroot collected in this directory some
material you may need to get it done.

This material is composed of the following items.
 * The scripts used to control compilation of the packages and the generation
   of image files, i.e. the Buildroot sources.
   Note: this has not been saved due to technical limitations, you must
   collect it manually.
 * The Buildroot configuration file; this has been saved in buildroot.config.
 * The toolchain (cross-compiler and related tools) used to generate all the
   compiled programs.
   Note: this may have not been saved due to technical limitations, you may
   need to collect it manually.
 * The original source code for target packages in the 'sources/'
   subdirectory and for host packages in the 'host-sources/' subdirectory
   (except for the non-redistributable packages, which have not been
   saved). Patches that were applied are also saved, along with a file
   named 'series' that lists the patches in the order they were
   applied. Patches are under the same license as the files that they
   modify in the original package.
   Note: Buildroot applies additional patches to Libtool scripts of
   autotools-based packages. These patches can be found under
   support/libtool in the Buildroot source and, due to technical
   limitations, are not saved with the package sources. You may need
   to collect them manually.
 * Two manifest files listing the configured packages and related
   information: 'manifest.csv' for target packages and 'host-manifest.csv'
   for host packages.
 * The license text of the packages, in the 'licenses/' and
   'host-licenses/' subdirectories for target and host packages
   respectively.

Due to technical limitations or lack of license definition in the package
makefile, some of the material listed above could not been saved, as the
following list details.

WARNING: the Buildroot source code has not been saved
WARNING: linux-headers-custom: cannot save license (LINUX_HEADERS_LICENSE_FILES not defined)
WARNING: linux-custom: cannot save license (LINUX_LICENSE_FILES not defined)
