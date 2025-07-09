###############################################################################
# Name: build_simulations.R
# Written for use with R version 4.3.2
#
# PURPOSE: 
# This script is for building simulations using the lixoftConnectors 
# R package. Simulations should match what would be generated using the Simulx 
# software interface. 
###############################################################################

# set up -----------------------------------------------------------------

library(lixoftConnectors)



# initialize connectors ---------------------------------------------------

lixoftConnectors::initializeLixoftConnectors(
  software = "simulx",
  path = "/srv/Lixoft/MonolixSuite2024R1/",
  force = TRUE)

# import the monolix mltran project and model files
lixoftConnectors::importProject()



# set simulation parameters -----------------------------------------------

## covariates

# getters
getCovariateElements()
# load while still in monolix
getCovariateInformation()$name

defineCovariateElement()

# endpoint
defineEndpoint()

# treatment
defineTreatmentElement()

defineTreatmentElement(name = "name", 
                       element = list(
                         probaMissDose=0, 
                         admID=1, 
                         repeats=c(cycleDuration = 1, NumberOfRepetitions=12), 
                         data=data.frame(start=1, interval=2, nbDoses=10, amount=1))
                       )

# output element = [comes after FIT in project file]
defineOutputElement()

defineOccasionElement()
# run simulation ----------------------------------------------------------

runSimulation()


# get simulation results --------------------------------------------------

getSimulationResults()
