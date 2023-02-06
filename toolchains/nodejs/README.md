<!-- Generated with Stardoc: http://skydoc.bazel.build -->



# Reference documentation

<a id="#nixpkgs_nodejs_configure"></a>

### nixpkgs_nodejs_configure

<pre>
nixpkgs_nodejs_configure(<a href="#nixpkgs_nodejs_configure-name">name</a>, <a href="#nixpkgs_nodejs_configure-attribute_path">attribute_path</a>, <a href="#nixpkgs_nodejs_configure-repository">repository</a>, <a href="#nixpkgs_nodejs_configure-repositories">repositories</a>, <a href="#nixpkgs_nodejs_configure-nix_platform">nix_platform</a>, <a href="#nixpkgs_nodejs_configure-nix_file">nix_file</a>,
                         <a href="#nixpkgs_nodejs_configure-nix_file_content">nix_file_content</a>, <a href="#nixpkgs_nodejs_configure-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_nodejs_configure-nixopts">nixopts</a>, <a href="#nixpkgs_nodejs_configure-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_nodejs_configure-quiet">quiet</a>,
                         <a href="#nixpkgs_nodejs_configure-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_nodejs_configure-target_constraints">target_constraints</a>)
</pre>



#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_nodejs_configure-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>"nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_platform">
<td><code>nix_platform</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
</tbody>
</table>


<a id="#nixpkgs_nodejs_configure_platforms"></a>

### nixpkgs_nodejs_configure_platforms

<pre>
nixpkgs_nodejs_configure_platforms(<a href="#nixpkgs_nodejs_configure_platforms-name">name</a>, <a href="#nixpkgs_nodejs_configure_platforms-platforms_mapping">platforms_mapping</a>, <a href="#nixpkgs_nodejs_configure_platforms-attribute_path">attribute_path</a>, <a href="#nixpkgs_nodejs_configure_platforms-repository">repository</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-repositories">repositories</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_platform">nix_platform</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_file">nix_file</a>, <a href="#nixpkgs_nodejs_configure_platforms-nix_file_content">nix_file_content</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-nix_file_deps">nix_file_deps</a>, <a href="#nixpkgs_nodejs_configure_platforms-nixopts">nixopts</a>, <a href="#nixpkgs_nodejs_configure_platforms-fail_not_supported">fail_not_supported</a>, <a href="#nixpkgs_nodejs_configure_platforms-quiet">quiet</a>,
                                   <a href="#nixpkgs_nodejs_configure_platforms-exec_constraints">exec_constraints</a>, <a href="#nixpkgs_nodejs_configure_platforms-target_constraints">target_constraints</a>, <a href="#nixpkgs_nodejs_configure_platforms-kwargs">kwargs</a>)
</pre>

Runs nixpkgs_nodejs_configure for each platform.

Since rules_nodejs adds platform suffix to repository name, this can be helpful
if one wants to use npm_install and reference js dependencies from npm repo.
See the example directory.


#### Parameters

<table class="params-table">
<colgroup>
<col class="col-param" />
<col class="col-description" />
</colgroup>
<tbody>
<tr id="nixpkgs_nodejs_configure_platforms-name">
<td><code>name</code></td>
<td>

optional.
default is <code>"nixpkgs_nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-platforms_mapping">
<td><code>platforms_mapping</code></td>
<td>

optional.
default is <code>{"aarch64-darwin": struct(exec_constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"], rules_nodejs_platform = "darwin_arm64", target_constraints = ["@platforms//os:macos", "@platforms//cpu:arm64"]), "x86_64-linux": struct(exec_constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"], rules_nodejs_platform = "linux_amd64", target_constraints = ["@platforms//os:linux", "@platforms//cpu:x86_64"]), "x86_64-darwin": struct(exec_constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"], rules_nodejs_platform = "darwin_amd64", target_constraints = ["@platforms//os:macos", "@platforms//cpu:x86_64"]), "aarch64-linux": struct(exec_constraints = ["@platforms//os:linux", "@platforms//cpu:arm64"], rules_nodejs_platform = "linux_arm64", target_constraints = ["@platforms//os:linux", "@platforms//cpu:arm64"])}</code>

<p>

struct describing mapping between nix platform and rules_nodejs bazel platform with
target and exec constraints

</p>
</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-attribute_path">
<td><code>attribute_path</code></td>
<td>

optional.
default is <code>"nodejs"</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-repository">
<td><code>repository</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-repositories">
<td><code>repositories</code></td>
<td>

optional.
default is <code>{}</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_platform">
<td><code>nix_platform</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file">
<td><code>nix_file</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file_content">
<td><code>nix_file_content</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nix_file_deps">
<td><code>nix_file_deps</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-nixopts">
<td><code>nixopts</code></td>
<td>

optional.
default is <code>[]</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-fail_not_supported">
<td><code>fail_not_supported</code></td>
<td>

optional.
default is <code>True</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-quiet">
<td><code>quiet</code></td>
<td>

optional.
default is <code>False</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-exec_constraints">
<td><code>exec_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-target_constraints">
<td><code>target_constraints</code></td>
<td>

optional.
default is <code>None</code>

</td>
</tr>
<tr id="nixpkgs_nodejs_configure_platforms-kwargs">
<td><code>kwargs</code></td>
<td>

optional.

</td>
</tr>
</tbody>
</table>


