// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

param principalId string
param roleDefinitionId string

param resourceName string

param roleAssignmentId string = guid(principalId, roleDefinitionId, resourceName)

resource existingResource 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: resourceName
}

resource symbolicname 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: roleAssignmentId
  scope: existingResource
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
