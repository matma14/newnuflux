# By C. Weaver

include build/config.mk

NNF_DIR       = $(shell pwd -P)
SrcSuf        = cpp
ObjSuf        = o
ExeSuf        =
DllSuf        = so
OutPutOpt     = -o

LIBDIR		  = lib
INCDIR		  = public
SRCDIR		  = private/NewNuFlux
OBJDIR		  = build

OS=$(shell uname -s)
ifeq ($(OS),Darwin) 
	DllSuf        = dylib
	SOFLAGS		  = -shared -flat_namespace -undefined dynamic_lookup -multiply_defined suppress 
#-Wl,-install_name,$(NF_DIR)/lib/libNewNuFlux.$(DllSuf)
	INSTALLNAME=-Wl,-install_name,$(NF_DIR)/lib/libNewNuFlux.$(DllSuf)
else
	SOFLAGS		  = -shared 
endif

USERCXXFLAGS := $(CXXFLAGS)
USERLDFLAGS := $(LDFLAGS)
CXXFLAGS = -std=c++11 -O2 -g -I$(INCDIR) -Wall -fPIC -Dstandalone -DNEWNUFLUX_DATADIR=\"$(NNF_DIR)\" $(USERCXXFLAGS)
LDFLAGS += $(USERLDFLAGS) -lphotospline

DYN_LIB=libNewNuFlux.$(DllSuf)
NEUTFLUXSO  = $(LIBDIR)/$(DYN_LIB)

SRCS = $(SRCDIR)/FluxFunction.cpp $(SRCDIR)/logging.cpp $(SRCDIR)/particleType.cpp $(SRCDIR)/Fluxes/LegacyConventionalFlux.cpp $(SRCDIR)/Fluxes/LegacyPromptFlux.cpp $(SRCDIR)/Fluxes/ANFlux.cpp $(SRCDIR)/Fluxes/LEFlux.cpp $(SRCDIR)/Fluxes/SplineFlux.cpp $(SRCDIR)/Fluxes/IPLEFlux.cpp

OBJSPAT = $(patsubst %$(SrcSuf),%$(ObjSuf), $(SRCS))
OBJS = $(patsubst $(SRCDIR)/%,$(OBJDIR)/%, $(OBJSPAT))

PYOBJECTS = $(OBJDIR)/module.o

all: $(NEUTFLUXSO) $(PYBINDINGS)

$(NEUTFLUXSO): $(OBJS)
	@test -d $(@D) || mkdir -p $(@D)
	@echo Linking $(NEUTFLUXSO)
	@$(CXX) $(OBJS) $(SOFLAGS) $(INSTALLNAME) $(LDFLAGS) -o $(NEUTFLUXSO)

clean:
	@echo "removing intermediate build files and products"
	@rm -rf $(OBJS) build/module.o $(NEUTFLUXSO) $(PYBINDINGS)

.SUFFIXES: .$(SrcSuf)

#.$(SrcSuf).$(ObjSuf): 
$(OBJDIR)/%$(ObjSuf): $(SRCDIR)/%$(SrcSuf)
	@test -d $(@D) || mkdir -p $(@D)
	@echo Compiling $< to $@
	@$(CXX) $(CXXFLAGS) -o $(@) -I$(INCDIR) ${INCALL} -c $<

$(OBJDIR)/module.o : $(SRCDIR)/../pybindings/module.cxx
	@echo Compiling python bindings
	@$(CXX) $(PYCXXFLAGS) -c $< -o $@

$(PYBINDINGS) : $(NEUTFLUXSO) $(PYOBJECTS)
	@echo Linking $(PYBINDINGS)
	@$(CXX) -dynamiclib $(SOFLAGS) $(PYOBJECTS) $(PYLDFLAGS) -o $(PYBINDINGS)

install: $(NEUTFLUXSO) $(PYBINDINGS)
	@echo Installing headers in $(PREFIX)/include/NewNuFlux
	@mkdir -p $(PREFIX)/include/NewNuFlux
	@cp $(INCDIR)/NewNuFlux/*.h $(PREFIX)/include/NewNuFlux/
	@mkdir -p $(PREFIX)/include/NewNuFlux/Fluxes
	@cp $(INCDIR)/NewNuFlux/Fluxes/*.h $(PREFIX)/include/NewNuFlux/Fluxes/
	@echo Installing libraries in $(PREFIX)/lib
	@mkdir -p $(PREFIX)/lib
	@cp $(NEUTFLUXSO) $(PREFIX)/lib/
	@echo Installing config information in $(PREFIX)/lib/pkgconfig
	@mkdir -p $(PREFIX)/lib/pkgconfig
	@cp $(LIBDIR)/newnuflux.pc $(PREFIX)/lib/pkgconfig
	@./check_install.sh newnuflux "$(PREFIX)"

uninstall: 
	@echo Removing headers from $(PREFIX)/include/NewNuFlux
	@rm -rf $(PREFIX)/include/NewNuFlux
	@echo Removing libraries from $(PREFIX)/lib
	@rm -f $(PREFIX)/lib/$(DYN_LIB)
	@echo Removing config information from $(PREFIX)/lib/pkgconfig
	@rm -f $(PREFIX)/lib/pkgconfig/newnuflux.pc

install-python : $(PYBINDINGS)
	@echo Installing python module to $(PYTHON_INSTALL_DIR)
	@mkdir -p $(PYTHON_INSTALL_DIR)
	@cp $(PYBINDINGS) $(PYTHON_INSTALL_DIR)/

uninstall-python : 
	@echo Removing python module from $(PYTHON_INSTALL_DIR)
	@rm -f $(PYTHON_INSTALL_DIR)/$(PYMODULE)
