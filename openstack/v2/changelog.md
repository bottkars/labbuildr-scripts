# Changelog

### Controller
  - Reformatted Code and Output
  - One Install Script serves for both OS Versions (install_controller.sh)
  - Shared Base Install Config scripts for both OS Versions 
    - install_mysql.sh
    - install_rabbitmq.sh
  - Shared  Base Config Script for both OS Versions
    - conv_env.sh
  - install_controller.sh has currently nor parameters, but requires the following somehow
    - LOGFILE (value currently fixed )
    - INSTALLPATH (value currently dynamic)
    - OSVERSION (value currently fixed)
    - CONFIGPATH (value currently dynamic)
    - CONTROLLERNAME (value currently dynamic)
    - CONTROLLERIP (value currently dynamic)
    - DOMAINSUFFIX (value currently from default.xml)
    - BUILDDOMAIN (value currently from default.xml)
    - MYSUBNET (value currently from default.xml)
    - DEFGW (value currently from default.xml but not needed)
    - DNS1 (value currently from default.xml but not needed)
    - DNS2 (value currently from default.xml but not needed)
    - SIO_GW (value currently fixed)
    - SIO_PD (value currently fixed)
    - SIO_SP (value currently fixed)
    - BASECONFIG (value currently fixed)

### Compute
  - Reformatted Code and Output
  - One Install Script serves for both OS Versions (install_compute.sh)
  - install_controller.sh has currently nor parameters, but requires the following somehow
    - LOGFILE (value currently fixed )
    - INSTALLPATH (value currently dynamic)
    - OSVERSION (value currently fixed)
    - CONFIGPATH (value currently dynamic)
    - LOCALNAME (value currently dynamic)
    - LOCALIP (value currently dynamic)
    - CONTROLLERNAME (value currently fixed)
    - CONTROLLERIP (value currently fixed)

### To Do (aka DoDo! =) ) 
- Determine how to feed install_controller.sh script with needed var values (at least the fixed ones)
- Determine how to feed install_compute.sh script with needed var values (at least the fixed ones)
- need to specify location of default.xml (if used in future)