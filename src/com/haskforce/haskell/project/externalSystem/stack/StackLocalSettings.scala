package com.haskforce.haskell.project.externalSystem.stack

import com.intellij.openapi.externalSystem.settings.AbstractExternalSystemLocalSettings
import com.intellij.openapi.project.Project

final class StackLocalSettings(project: Project)
  extends AbstractExternalSystemLocalSettings(
    StackManager.PROJECT_SYSTEM_ID,
    project
  )


