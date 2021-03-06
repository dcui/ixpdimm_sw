#
# Copyright (c) 2015 2016 2018, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of Intel Corporation nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if(NOT BUILDNUM)
	execute_process(COMMAND git describe --abbrev=0 OUTPUT_VARIABLE BUILDNUM)

	if("${BUILDNUM}" MATCHES "^([a-zA-Z-]*v)(.*)$")
		#replace
		string(REGEX REPLACE "^([a-zA-Z-]*v)" "" BUILDNUM "${BUILDNUM}")
		string(REGEX REPLACE "\n$" "" BUILDNUM "${BUILDNUM}")
	else()
		execute_process(COMMAND pwd OUTPUT_VARIABLE BUILDNUM)
		if(NOT "${BUILDNUM}" MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)\\.([0-9]+)$")
			set(BUILDNUM 99.99.99.9999)
		endif()
	endif()
endif()

string(REPLACE "." ";" VERSION_LIST "${BUILDNUM}")

list(GET VERSION_LIST 0 VERSION_MAJOR)
list(GET VERSION_LIST 1 VERSION_MINOR)
list(GET VERSION_LIST 2 VERSION_HOTFIX)
list(GET VERSION_LIST 3 VERSION_BUILDNUM)

#Target names
if(MSVC)
	set(MARKETING_PRODUCT_NAME libixpdimm_sw)
	set(COMMON_LIB_NAME libixpdimm-common)
	set(API_LIB_NAME libixpdimm)
	set(CORE_LIB_NAME libixpdimm-core)
	set(CLI_LIB_NAME libixpdimm-cli)
	set(CLI_MANF_LIB_NAME libixpdimm-cli_manf)
	set(CIM_LIB_NAME libixpdimm-cim)
else()
	set(MARKETING_PRODUCT_NAME ixpdimm_sw)
	set(COMMON_LIB_NAME ixpdimm-common)
	set(API_LIB_NAME ixpdimm)
	set(CORE_LIB_NAME ixpdimm-core)
	set(CLI_LIB_NAME libixpdimm-cli)
	set(CLI_MANF_LIB_NAME ixpdimm-cli_manf)
	set(CIM_LIB_NAME ixpdimm-cim)
endif()

set(CLI_NAME ixpdimm-cli)
set(MONITOR_NAME ixpdimm-monitor)

# FIXME - Consider using -D based on the library name
# example: -Dixpdimm_cim_EXPORTS
set(NVM_DLL_DEF "-D__NVM_DLL__")
set(API_LIB_EXPORT_DEF "-D__NVM_API_DLL_EXPORTS__")
set(COMMON_LIB_EXPORT_DEF "-D__NVM_COMMON_DLL_EXPORTS__")
set(CORE_LIB_EXPORT_DEF "-D__NVM_CORE_DLL_EXPORTS__")
set(CLI_LIB_EXPORT_DEF "-D__NVM_CLI_DLL_EXPORTS__")
set(CIM_LIB_EXPORT_DEF "-D__NVM_CIM_DLL_EXPORTS__")

# Set all libs to 1.0.0 until we start versioning API's
set(LIB_BUILD_VERSION 1.0.0)
set(SO_BUILD_VERSION 1)

if(LNX_BUILD)
	set(LINUX_PRODUCT_NAME  ${MARKETING_PRODUCT_NAME})
	set(PRODUCT_DATADIR "/var/lib/${LINUX_PRODUCT_NAME}")
	if(NOT RPMBUILD_DIR)
		set(RPMBUILD_DIR ${ROOT}/output/rpmbuild)
	endif()
		set(MGMT_ENV_DIR "/opt/mgmt_env")
		set(DOXYGEN "${MGMT_ENV_DIR}/doxygen/doxygen")

		if(EXISTS "/etc/redhat-release")
			set(LINUX_DIST rel)
		elseif(EXISTS "/etc/SuSE-release")
			set(LINUX_DIST sle)
		elseif(EXISTS "/etc/debian_version")
			set(LINUX_DIST debian)
		else()
			set(LINUX_DIST Unrecognized Linux distribution)
		endif()
elseif(WIN_BUILD)
	if(MSVC)
		set(CMAKE_MC_COMPILER $ENV{WindowsSdkVerBinPath}/x64/mc.exe)
		set(CMAKE_RES_COMPILER $ENV{WindowsSdkVerBinPath}/x64/rc.exe)
		set(VS_LINK link.exe)
		set(OBJECT_MODULE_DIR ${ROOT}/output/obj/${OS_TYPE}/${ADAPTER_TYPE}/${BUILD_TYPE})
	else()
		set(MGMT_ENV_DIR "C:/mgmt_env")
		set(DOXYGEN "${MGMT_ENV_DIR}/doxygen/doxygen.exe")
		set(WINDMC c:/mgmt_env/mingw_w64/bin/windmc.exe)
		set(WINDRES c:/mgmt_env/mingw_w64/bin/windres.exe)
		set(OBJECT_MODULE_DIR ${ROOT}/output/obj/${OS_TYPE}/${ADAPTER_TYPE}/${BUILD_TYPE})
		set(LIBSSP "${MINGW_DIR}/bin/libssp-0.dll")
	endif()
endif()

file(GLOB INSTALL_FILES
	src/lib/nvm_management.h
	src/lib/nvm_types.h
	src/lib/export_api.h
	src/monitor/ixpdimm-monitor.service
	src/common/encrypt/public.rev0.pem
	Help.pdf
	REPORTING_ISSUES
	TROUBLESHOOTING
	)

if(WIN_BUILD)
	list(APPEND INSTALL_FILES ${ROOT}/install/windows/rel-release/nvdimm-mgmt-windows-installer.bom)
endif()

file(COPY ${INSTALL_FILES} DESTINATION ${OUTPUT_DIR})
