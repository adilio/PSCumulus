---
document type: cmdlet
external help file: PSCumulus-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSCumulus
PlatyPS schema version: 2024-05-01
title: Get-CloudResource
---

# Get-CloudResource

## SYNOPSIS

Resolves a CloudPath to live cloud resources.

## SYNTAX

### __AllParameterSets

```
Get-CloudResource [-Path] <string> [-Detailed] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  None

## DESCRIPTION

Get-CloudResource takes a CloudPath string (the same grammar that
Resolve-CloudPath parses), dispatches to the matching provider backend,
and returns normalized CloudRecord objects.

The path must reach at least Kind depth:

    {Provider}:\{Scope}\{Kind}[\{ResourceName}]

A Kind-depth path (for example 'Azure:\prod-rg\Instances') lists every
resource of that kind in the scope.
A Resource-depth path (for example
'Azure:\prod-rg\Instances\web-01') returns the single matching resource,
or writes a non-terminating error when nothing matches.

The Tags kind is not addressable through Get-CloudResource; use
Get-CloudTag for tag queries.

## EXAMPLES

### EXAMPLE 1

Get-CloudResource 'Azure:\prod-rg\Instances\web-server-01'

Returns the normalized record for one Azure VM.

### EXAMPLE 2

Get-CloudResource 'AWS:\us-east-1\Disks'

Lists every EBS volume in the region as CloudRecord objects.

### EXAMPLE 3

Get-CloudResource 'GCP:\my-project\Functions\resize-images' -Detailed

Returns a GCP Cloud Function with the detailed view enabled.

### EXAMPLE 4

'Azure:\prod-rg\Storage\proddata01' | Get-CloudResource | Set-CloudTag -Tags @{ owner = 'ops' }

Resolves a storage account by path and pipes it into tagging.

## PARAMETERS

### -Detailed

Emit detailed view records.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Path

The CloudPath to resolve.
Must include at least Provider, Scope, and Kind.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

See the command description and examples above.

## OUTPUTS

### System.Management.Automation.PSObject

See the command description and examples above.

## NOTES

## RELATED LINKS

None.


