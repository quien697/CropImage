## MODIFIED Requirements

### Requirement: Output Size Limit
`outputSide` SHALL be greater than 0 and at most 8192. Creating a `CropImageView` with an
`outputSide` outside that range SHALL stop with a precondition failure, rather than later
delivering a blank image or `nil`.

#### Scenario: Output side over the limit
- **WHEN** an app creates `CropImageView` with `outputSide` 10000
- **THEN** the app stops with the precondition failure "outputSide must be greater than 0 and at most 8192 pixels"

#### Scenario: Output side of zero
- **WHEN** an app creates `CropImageView` with `outputSide` 0
- **THEN** the app stops with the precondition failure "outputSide must be greater than 0 and at most 8192 pixels"
