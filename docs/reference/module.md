---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: 
Locale: en-US
Module Guid: 9e7bb15e-7fc3-47ec-a6f9-86a8b4478fd7
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: PSCumulus Module Reference
---

# PSCumulus Module

## Description

Cross-cloud PowerShell module for Azure, AWS, and GCP. Unified commands (Get-CloudInstance, Get-CloudStorage, etc.) return normalized objects with a consistent output shape across all three providers.

## PSCumulus

### [Connect-Cloud](commands/Connect-Cloud.md)

Prepares a ready-to-use cloud session for the specified provider.

### [Disconnect-Cloud](commands/Disconnect-Cloud.md)

Clears PSCumulus session context for a specific cloud provider.

### [Get-CloudContext](commands/Get-CloudContext.md)

Returns the current PSCumulus session context for all connected providers.

### [Get-CloudDisk](commands/Get-CloudDisk.md)

Gets managed disks from a selected cloud provider.

### [Get-CloudFunction](commands/Get-CloudFunction.md)

Gets serverless functions from a selected cloud provider.

### [Get-CloudInstance](commands/Get-CloudInstance.md)

Gets compute instances from a selected cloud provider.

### [Get-CloudNetwork](commands/Get-CloudNetwork.md)

Gets virtual networks from a selected cloud provider.

### [Get-CloudStorage](commands/Get-CloudStorage.md)

Gets storage resources from a selected cloud provider.

### [Get-CloudTag](commands/Get-CloudTag.md)

Gets resource tags or labels from a selected cloud provider.

### [Resolve-CloudPath](commands/Resolve-CloudPath.md)

Parses a cloud path string into a structured CloudPath object.

### [Start-CloudInstance](commands/Start-CloudInstance.md)

Starts a compute instance on a selected cloud provider.

### [Stop-CloudInstance](commands/Stop-CloudInstance.md)

Stops a compute instance on a selected cloud provider.


